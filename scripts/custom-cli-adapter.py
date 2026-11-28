#!/usr/bin/env python3
"""Resolve a custom CLI lane to an executable and an exact model ID."""

import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import stat
import subprocess
import sys
import threading
import tempfile
import time
import uuid


class RouteError(Exception):
    """An active custom route cannot be resolved safely."""


ROLE_MODES = {"implementer": "workspace-write", "tester": "workspace-write", "reviewer": "read-only"}
BLOCKED_SETTING = re.compile(r"(MODEL|SANDBOX|PERMISSION|WRITE_SCOPE|UNSAFE)", re.I)
SECRET_SETTING = re.compile(r"(TOKEN|KEY|PASSWORD|SECRET|CREDENTIAL)", re.I)
SANDBOX_EXEC = Path("/usr/bin/sandbox-exec")
MAX_METADATA_BYTES = 65536
INVOCATION_TIMEOUT_SECONDS = 3600


def parse_custom_lane(lane):
    if not lane.startswith("cli:"):
        return None
    route = lane[4:]
    adapter, separator, model = route.partition("/")
    if not separator or not adapter.strip() or not model.strip():
        raise RouteError("expected cli:<adapter>/<model>")
    return adapter, model


def read_config(config_path):
    try:
        config = json.loads(Path(config_path).read_text())
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise RouteError(f"cannot read valid JSON config: {error}") from error
    if not isinstance(config, dict):
        raise RouteError("config must contain a JSON object")
    return config


def resolve_executable(entry):
    if not isinstance(entry, str) or not entry.strip():
        raise RouteError("selected adapter must map to a non-empty absolute executable path")
    executable = Path(entry).expanduser()
    if not executable.is_absolute():
        raise RouteError("executable path must be absolute")
    try:
        canonical_path = executable.resolve(strict=True)
    except (OSError, RuntimeError) as error:
        raise RouteError(f"executable path cannot be resolved: {error}") from error
    if not canonical_path.is_file() or not os.access(canonical_path, os.X_OK):
        raise RouteError("executable path must name an executable file")
    try:
        digest = hashlib.sha256(canonical_path.read_bytes()).hexdigest()
    except OSError as error:
        raise RouteError(f"cannot read executable for SHA-256: {error}") from error
    return str(canonical_path), digest


def resolve_route(config_path, lane):
    route = parse_custom_lane(lane)
    if route is None:
        return {"status": "no-custom-adapter", "route": lane}
    adapter, model = route
    if adapter == "codex":
        return {"status": "no-custom-adapter", "route": lane}
    return resolve_custom_route(read_config(config_path), lane, adapter, model)


def resolve_custom_route(config, lane, adapter, model):
    adapters = config.get("cli_adapters", {})
    if not isinstance(adapters, dict):
        raise RouteError("cli_adapters must be a JSON object")
    if adapter not in adapters:
        raise RouteError(f"adapter {adapter!r} is not configured")
    executable, digest = resolve_executable(adapters[adapter])
    return {
        "status": "custom-adapter",
        "adapter": adapter,
        "executable": executable,
        "sha256": digest,
        "model": model,
        "route": lane,
    }


def canonical_directory(path, label):
    try:
        resolved = Path(path).resolve(strict=True)
    except (OSError, RuntimeError) as error:
        raise RouteError(f"{label} cannot be resolved: {error}") from error
    if not resolved.is_dir():
        raise RouteError(f"{label} must be a directory")
    return resolved


def canonical_file(path, label):
    candidate = Path(path)
    if candidate.is_symlink():
        raise RouteError(f"{label} cannot be a symlink")
    try:
        resolved = candidate.resolve(strict=True)
    except (OSError, RuntimeError) as error:
        raise RouteError(f"{label} cannot be resolved: {error}") from error
    if not resolved.is_file():
        raise RouteError(f"{label} must be a file")
    return resolved


def canonical_new_file(path, repo):
    candidate = Path(path)
    if candidate.exists() or candidate.is_symlink():
        raise RouteError("authorized new task file must be an absent, non-symlink path")
    parent = canonical_directory(candidate.parent, "authorized task file parent")
    resolved = parent / candidate.name
    if not candidate.name or candidate.name in {".", ".."} or not is_within(resolved, repo):
        raise RouteError("authorized new task file must stay inside the repository")
    return resolved


def routing_root_for(repo):
    features = repo / "docs/features"
    if features.is_symlink():
        raise RouteError("docs/features cannot be a symlink")
    features = canonical_directory(features, "docs/features")
    routing = features / ".routing"
    if routing.is_symlink():
        raise RouteError("target docs/features/.routing cannot be a symlink")
    if not routing.exists():
        routing.mkdir(mode=0o700)
    resolved = canonical_directory(routing, "target docs/features/.routing")
    if not is_within(resolved, repo):
        raise RouteError("target docs/features/.routing must stay inside the repository")
    if resolved.stat().st_uid != os.getuid() or resolved.stat().st_mode & 0o022:
        raise RouteError("target docs/features/.routing must be controller-owned and not group/world-writable")
    return resolved


def ensure_private_directory(path, label, parent):
    path = Path(path)
    if path.is_symlink():
        raise RouteError(f"{label} cannot be a symlink")
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    resolved = canonical_directory(path, label)
    if not is_within(resolved, parent):
        raise RouteError(f"{label} must stay under the protected routing root")
    if resolved.stat().st_uid != os.getuid() or resolved.stat().st_mode & 0o077:
        raise RouteError(f"{label} must be private and owned by the controller")
    return resolved


def atomic_write(path, content, mode=0o600):
    path = Path(path)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}-", dir=str(path.parent))
    try:
        os.fchmod(descriptor, mode)
        with os.fdopen(descriptor, "wb") as output:
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
        directory_fd = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    except BaseException:
        try:
            os.close(descriptor)
        except OSError:
            pass
        try:
            os.unlink(temporary)
        except OSError:
            pass
        raise


def write_json(path, value):
    atomic_write(path, (json.dumps(value, sort_keys=True, indent=2) + "\n").encode())


@contextmanager
def work_item_lock(routing_root, role, work_item):
    lock_directory = ensure_private_directory(routing_root / "locks", "work-item lock directory", routing_root)
    lock_path = lock_directory / f"{role}-{work_item}.lock"
    if lock_path.is_symlink():
        raise RouteError("work-item lock cannot be a symlink")
    descriptor = os.open(lock_path, os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    with os.fdopen(descriptor, "a+") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(lock_file, fcntl.LOCK_UN)


def git_output(repo, *arguments, env=None, check=True):
    try:
        result = subprocess.run(
            ["git", "--literal-pathspecs", "-C", str(repo), *arguments], capture_output=True, text=True,
            check=False, env=env,
        )
    except OSError as error:
        raise RouteError(f"cannot run Git operation: {error}") from error
    if check and result.returncode != 0:
        raise RouteError(f"Git operation failed: {result.stderr.strip() or result.returncode}")
    return result


def git_output_bytes(repo, *arguments, input_bytes):
    try:
        result = subprocess.run(
            ["git", "--literal-pathspecs", "-C", str(repo), *arguments], capture_output=True, check=False,
            input=input_bytes,
        )
    except OSError as error:
        raise RouteError(f"cannot run Git operation: {error}") from error
    if result.returncode != 0:
        detail = result.stderr.decode(errors="replace").strip()
        raise RouteError(f"Git operation failed: {detail or result.returncode}")
    return result


def repo_file(repo, value, label, allow_missing=False):
    candidate = Path(value)
    if not candidate.is_absolute():
        candidate = repo / candidate
    if candidate.is_symlink():
        raise RouteError(f"{label} cannot be a symlink")
    if candidate.exists():
        resolved = canonical_file(candidate, label)
    elif allow_missing:
        resolved = canonical_new_file(candidate, repo)
    else:
        raise RouteError(f"{label} is missing")
    if not is_within(resolved, repo):
        raise RouteError(f"{label} must stay inside the repository")
    return resolved


def file_state(repo, value):
    path = repo_file(repo, value, "authorized task path", allow_missing=True)
    relative = path.relative_to(repo).as_posix()
    exists = path.is_file()
    content_digest = hashlib.sha256(path.read_bytes()).hexdigest() if exists else None
    executable = bool(path.stat().st_mode & stat.S_IXUSR) if exists else None
    index = git_output(repo, "ls-files", "--stage", "--", relative).stdout.strip()
    committed = git_output(repo, "ls-tree", "HEAD", "--", relative).stdout.strip()
    status = git_output(repo, "status", "--porcelain=v1", "--", relative).stdout.strip()
    index_blob = index.split()[1] if index else None
    committed_blob = committed.split()[2] if committed else None
    clean = (exists and not status and index_blob is not None and index_blob == committed_blob) or (
        not exists and not status and index_blob is None and committed_blob is None
    )
    return {
        "path": relative,
        "exists": exists,
        "content_sha256": content_digest,
        "worktree_executable": executable,
        "index_entry": index,
        "committed_entry": committed,
        "status": status,
        "clean_at_claim": clean,
    }


def validate_work_item(work_item):
    if not re.fullmatch(r"[A-Za-z0-9_.-]{1,100}", work_item):
        raise RouteError("work item must use letters, digits, dot, underscore, or hyphen")


def claim_attempt(args):
    repo = canonical_directory(args.repo, "repository")
    routing_root = routing_root_for(repo)
    validate_work_item(args.work_item)
    if args.role not in ROLE_MODES:
        raise RouteError(f"unsupported role {args.role!r}")
    if args.role == "reviewer" and args.write_path:
        raise RouteError("reviewer claims cannot include workspace write paths")
    if args.role == "reviewer" and args.expected_identity is None:
        raise RouteError("reviewer claims require the review batch's --expected-identity")
    if not args.lane.strip():
        raise RouteError("saved route cannot be empty")
    parsed_route = parse_custom_lane(args.lane)
    if parsed_route is None:
        raise RouteError("custom CLI claims require a cli:<adapter>/<exact-model> route")
    config = read_config(args.config)
    resolution = resolve_custom_route(config, args.lane, *parsed_route)
    adapter = resolution["adapter"]
    config_digest = configuration_identity(config, adapter)
    if args.expected_identity is not None:
        _, settings = effective_settings(config, adapter)
        require_adapter_identity(args.expected_identity, adapter_identity(resolution, config_digest, settings))
    if args.role == "implementer" and not args.write_path:
        raise RouteError("a claim must capture at least one exact authorized write path")
    if len({str(Path(path).resolve()) for path in args.write_path}) != len(args.write_path):
        raise RouteError("claim write paths must be unique")
    claims_directory = ensure_private_directory(routing_root / "claims", "claims directory", routing_root)
    claim_directory = ensure_private_directory(claims_directory / args.role, "role claims directory", routing_root)
    attempt_root = ensure_private_directory(routing_root / "attempts", "attempt directory root", routing_root)
    claim_path = claim_directory / f"{args.work_item}.json"
    with work_item_lock(routing_root, args.role, args.work_item):
        previous = None
        if claim_path.exists():
            if claim_path.is_symlink():
                raise RouteError("existing claim cannot be a symlink")
            try:
                previous = json.loads(claim_path.read_text())
            except (OSError, UnicodeError, json.JSONDecodeError) as error:
                raise RouteError(f"existing claim is unreadable; refusing replacement: {error}") from error
            if previous.get("state") not in {"finalized", "stopped"}:
                raise RouteError("work item already has a live or pending claim")
            if (previous.get("outcome") != "failed"
                    or previous.get("stages", {}).get("run", {}).get("status") == "complete"):
                raise RouteError("work item has a terminal disposition and cannot be relaunched")
            if not args.retry_claim or args.retry_claim != previous.get("claim_id"):
                raise RouteError("a failed work item requires an explicit retry of its recorded claim")
            if previous.get("route") != args.lane:
                raise RouteError("saved route changed; reconcile the prior disposition before starting a claim")
            previous_checkpoint = previous.get("checkpoint_path")
            previous_digest = previous.get("checkpoint_sha256")
            if previous_checkpoint and previous_digest:
                checkpoint_path = repo_file(repo, previous_checkpoint, "saved workflow checkpoint")
                if hashlib.sha256(checkpoint_path.read_bytes()).hexdigest() != previous_digest:
                    raise RouteError("workflow state changed after the prior disposition; reconcile before a new claim")
        elif args.retry_claim:
            raise RouteError("no prior failed claim matches the requested retry")
        baseline = [file_state(repo, path) for path in args.write_path]
        if previous and baseline != previous.get("write_paths"):
            raise RouteError("the previous write scope has not been reconciled to its saved baseline")
        head_sha = git_output(repo, "rev-parse", "HEAD").stdout.strip()
        if previous and head_sha != previous.get("head_sha"):
            raise RouteError("repository head changed since the failed attempt; reconcile before retrying")
        claim_id = uuid.uuid4().hex
        attempt_dir = attempt_root / claim_id
        attempt_dir.mkdir(mode=0o700)
        claim = {
            "schema_version": 1,
            "claim_id": claim_id,
            "attempt_id": claim_id,
            "role": args.role,
            "work_item": args.work_item,
            "repo": str(repo),
            "route": args.lane,
            "configuration_sha256": config_digest,
            "executable_sha256": resolution["sha256"],
            "head_sha": head_sha,
            "write_paths": baseline,
            "state": "active",
            "attempt_dir": str(attempt_dir),
        }
        if args.expected_identity is not None:
            claim["adapter_identity_sha256"] = args.expected_identity
        write_json(claim_path, claim)
    print(json.dumps({**claim, "claim_path": str(claim_path)}, sort_keys=True))
    return 0


def claim_file_for(routing_root, role, work_item):
    validate_work_item(work_item)
    return routing_root / "claims" / role / f"{work_item}.json"


def update_claim_locked(claim_path, routing_root, role, work_item, updater):
    with work_item_lock(routing_root, role, work_item):
        if Path(claim_path).is_symlink():
            raise RouteError("claim record cannot be a symlink")
        try:
            claim = json.loads(claim_path.read_text())
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            raise RouteError(f"cannot read claim record: {error}") from error
        updater(claim)
        write_json(claim_path, claim)
    return claim


def authorize_stage(args):
    repo = canonical_directory(args.repo, "repository")
    routing_root = routing_root_for(repo)
    claim_path = claim_file_for(routing_root, args.role, args.work_item)
    authorization_id = uuid.uuid4().hex

    def update(claim):
        if claim.get("claim_id") != args.claim_id or claim.get("state") != "active":
            raise RouteError("stage authorization requires the matching active claim")
        if git_output(repo, "rev-parse", "HEAD").stdout.strip() != claim.get("head_sha"):
            raise RouteError("repository head changed after claim; refusing stage authorization")
        stages = claim.setdefault("stages", {})
        if args.stage in stages:
            raise RouteError(f"{args.stage} authorization already exists and cannot be reissued")
        current = [file_state(repo, item["path"]) for item in claim.get("write_paths", [])]
        if args.stage == "probe":
            expected = claim.get("write_paths", [])
        else:
            probe = stages.get("probe")
            if not probe or probe.get("status") != "complete" or not probe.get("baseline_unchanged"):
                raise RouteError("run authorization requires a completed, unchanged probe stage")
            expected = probe.get("post_baseline", [])
        if current != expected:
            raise RouteError("write-scope baseline changed before stage authorization; reconcile first")
        stages[args.stage] = {
            "authorization_id": authorization_id,
            "status": "ready",
            "driver_handle": None,
            "released": False,
            "baseline": current,
        }

    claim = update_claim_locked(claim_path, routing_root, args.role, args.work_item, update)
    print(json.dumps({"claim_id": claim["claim_id"], "stage": args.stage, "authorization_id": authorization_id}, sort_keys=True))
    return 0


def bind_driver(args):
    repo = canonical_directory(args.repo, "repository")
    routing_root = routing_root_for(repo)
    claim_path = claim_file_for(routing_root, args.role, args.work_item)
    if not process_is_alive(args.handle):
        raise RouteError("driver handle is not a live process")

    def update(claim):
        if claim.get("claim_id") != args.claim_id or claim.get("state") != "active":
            raise RouteError("driver binding requires the matching active claim")
        stage = claim.get("stages", {}).get(args.stage)
        if not stage or stage.get("authorization_id") != args.authorization_id or stage.get("status") != "ready":
            raise RouteError("driver binding does not match a ready stage authorization")
        if stage.get("driver_handle") is not None:
            raise RouteError("stage authorization already has a bound driver")
        stage["driver_handle"] = args.handle

    update_claim_locked(claim_path, routing_root, args.role, args.work_item, update)
    print(json.dumps({"status": "bound", "driver_handle": args.handle, "stage": args.stage}))
    return 0


def release_driver(args):
    repo = canonical_directory(args.repo, "repository")
    routing_root = routing_root_for(repo)
    claim_path = claim_file_for(routing_root, args.role, args.work_item)

    def update(claim):
        if claim.get("claim_id") != args.claim_id or claim.get("state") != "active":
            raise RouteError("driver release requires the matching active claim")
        stage = claim.get("stages", {}).get(args.stage)
        if not stage or stage.get("authorization_id") != args.authorization_id:
            raise RouteError("driver release does not match the stage authorization")
        if stage.get("driver_handle") != args.handle or not process_is_alive(args.handle):
            raise RouteError("driver release requires the recorded live driver handle")
        if stage.get("status") != "ready" or stage.get("released"):
            raise RouteError("stage authorization is not ready for its single release")
        stage["released"] = True

    update_claim_locked(claim_path, routing_root, args.role, args.work_item, update)
    print(json.dumps({"status": "released", "driver_handle": args.handle, "stage": args.stage}))
    return 0


def process_is_alive(process_id):
    if process_id <= 0:
        return False
    try:
        os.kill(process_id, 0)
        return True
    except (ProcessLookupError, PermissionError, OSError):
        return False


def process_is_gone(process_id, *, group=False):
    if type(process_id) is not int or process_id <= 0:
        return False
    try:
        (os.killpg if group else os.kill)(process_id, 0)
    except ProcessLookupError:
        return True
    except OSError:
        return False
    return False


def settle_stage(args):
    repo = canonical_directory(args.repo, "repository")
    routing_root = routing_root_for(repo)
    claim_path = claim_file_for(routing_root, args.role, args.work_item)

    def update(claim):
        stage = claim.get("stages", {}).get(args.stage)
        if (claim.get("claim_id") != args.claim_id or claim.get("state") != "active"
                or not stage or stage.get("authorization_id") != args.authorization_id
                or stage.get("status") != "consumed"):
            raise RouteError("settlement requires the matching consumed stage of an active claim")
        if not stage.get("adapter_process_group"):
            raise RouteError("adapter process group was never recorded; keep the claim pending")
        if (not process_is_gone(stage.get("driver_handle"))
                or not process_is_gone(stage["adapter_process_group"], group=True)):
            raise RouteError("driver and adapter process-group absence must both be verified; keep the claim pending")
        stage["status"] = "failed"
        stage["execution_recorded"] = True
        stage["failure"] = "driver and adapter process group absent after interruption; exit status unknown"

    update_claim_locked(claim_path, routing_root, args.role, args.work_item, update)
    print(json.dumps({"status": "failed", "stage": args.stage, "claim_id": args.claim_id}))
    return 0


def run_claimed_driver(args):
    repo = canonical_directory(args.repo, "repository")
    routing_root = routing_root_for(repo)
    claim_path = claim_file_for(routing_root, args.role, args.work_item)
    try:
        initial_claim = json.loads(claim_path.read_text())
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise RouteError(f"cannot read active claim: {error}") from error
    if initial_claim.get("claim_id") != args.claim_id:
        raise RouteError("driver does not match the active claim")
    if args.role == "reviewer" and not initial_claim.get("adapter_identity_sha256"):
        raise RouteError("reviewer claim lacks a pinned review batch identity")
    attempt_dir = canonical_directory(initial_claim["attempt_dir"], "attempt directory")
    report_parent = canonical_directory(Path(args.report).parent, "worker report directory")
    receipt_parent = canonical_directory(Path(args.receipt).parent, "controller receipt directory")
    if not is_within(report_parent, attempt_dir) or not is_within(receipt_parent, attempt_dir):
        raise RouteError("report and receipt must stay inside this claim's attempt directory")
    if is_within(receipt_parent, report_parent):
        raise RouteError("controller receipt must stay outside the worker report directory")
    pid = os.getpid()
    print(json.dumps({"status": "waiting", "driver_handle": pid, "stage": args.stage}), file=sys.stderr, flush=True)
    deadline = time.monotonic() + args.barrier_timeout
    while time.monotonic() < deadline:
        try:
            claim = json.loads(claim_path.read_text())
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            raise RouteError(f"cannot read claim while waiting at driver barrier: {error}") from error
        if claim.get("claim_id") != args.claim_id or claim.get("state") != "active":
            raise RouteError("claim changed before the driver barrier opened")
        if (claim.get("repo") != str(repo) or claim.get("role") != args.role or claim.get("route") != args.lane
                or configuration_identity(read_config(args.config), parse_custom_lane(args.lane)[0]) != claim.get("configuration_sha256")):
            raise RouteError("driver configuration no longer matches the active claim")
        adapter_name = parse_custom_lane(args.lane)[0]
        adapters = read_config(args.config).get("cli_adapters", {})
        if not isinstance(adapters, dict) or adapter_name not in adapters:
            raise RouteError("claimed adapter is no longer configured")
        _, executable_digest = resolve_executable(adapters[adapter_name])
        if executable_digest != claim.get("executable_sha256"):
            raise RouteError("adapter executable changed after claim; refusing launch")
        allowed_paths = sorted(item["path"] for item in claim.get("write_paths", []))
        requested_paths = sorted(str(Path(path).resolve()) for path in args.write_path)
        claimed_paths = sorted(str(repo / path) for path in allowed_paths)
        if requested_paths != claimed_paths:
            raise RouteError("driver write scope differs from the captured claim baseline")
        stage = claim.get("stages", {}).get(args.stage)
        if stage and stage.get("authorization_id") == args.authorization_id:
            if stage.get("driver_handle") not in (None, pid):
                raise RouteError("another driver handle is bound to this authorization")
            if stage.get("driver_handle") == pid and stage.get("released"):
                break
        time.sleep(0.05)
    else:
        raise RouteError("driver barrier timed out before a bound handle was released")

    def consume(claim):
        stage = claim.get("stages", {}).get(args.stage)
        if (claim.get("claim_id") != args.claim_id or claim.get("state") != "active" or not stage
                or stage.get("authorization_id") != args.authorization_id
                or stage.get("driver_handle") != pid or not stage.get("released")
                or stage.get("status") != "ready"):
            raise RouteError("launch authorization is stale, consumed, or unbound")
        if git_output(repo, "rev-parse", "HEAD").stdout.strip() != claim.get("head_sha"):
            raise RouteError("repository head changed after claim; refusing launch")
        current = [file_state(repo, item["path"]) for item in claim.get("write_paths", [])]
        if current != stage.get("baseline"):
            raise RouteError("write-scope baseline changed at launch; refusing to start the wrapper")
        stage["status"] = "consumed"
        stage["consumed_at"] = time.time()

    claim = update_claim_locked(claim_path, routing_root, args.role, args.work_item, consume)
    args.command = args.stage
    process_group = None

    def launched_stage(claim):
        stage = claim.get("stages", {}).get(args.stage)
        if (claim.get("claim_id") != args.claim_id or claim.get("state") != "active"
                or not stage or stage.get("authorization_id") != args.authorization_id
                or stage.get("driver_handle") != pid or stage.get("status") != "consumed"):
            raise RouteError("launch evidence does not match the consumed authorization")
        return stage

    def record_launch(group_id):
        nonlocal process_group
        process_group = group_id

        def update(claim):
            launched_stage(claim)["adapter_process_group"] = group_id

        update_claim_locked(claim_path, routing_root, args.role, args.work_item, update)

    error = None
    result = None
    try:
        result = invoke_adapter(args.stage, args, record_launch, claim.get("adapter_identity_sha256"))
    except (RouteError, OSError) as invocation_error:
        error = str(invocation_error)
    if process_group is not None and not process_is_gone(process_group, group=True):
        detail = f"{error}. " if error else ""
        raise RouteError(f"{detail}adapter process-group absence could not be verified; keep the claim pending")

    def record_execution(claim):
        stage = launched_stage(claim)
        stage["execution_handle"] = pid
        stage["exit_status"] = result
        stage["execution_recorded"] = True
        stage["status"] = "failed"
        if error:
            stage["failure"] = error
        try:
            post_baseline = [file_state(repo, item["path"]) for item in claim.get("write_paths", [])]
            stage["post_baseline"] = post_baseline
            stage["baseline_unchanged"] = post_baseline == stage.get("baseline")
            if args.stage == "run" and result == 0:
                report_path = canonical_file(args.report, "completed worker report")
                if not is_within(report_path, Path(claim["attempt_dir"])):
                    raise RouteError("completed worker report is outside the attempt")
                stage["report_path"] = str(report_path)
                stage["report_sha256"] = hashlib.sha256(report_path.read_bytes()).hexdigest()
        except (RouteError, OSError) as evidence_error:
            stage.setdefault("failure", str(evidence_error))
            return
        if args.stage == "probe" and not stage["baseline_unchanged"]:
            stage["status"] = "invalidated"
        elif result == 0:
            stage["status"] = "complete"

    claim = update_claim_locked(claim_path, routing_root, args.role, args.work_item, record_execution)
    current_stage = claim["stages"][args.stage]
    if current_stage.get("failure"):
        raise RouteError(current_stage["failure"])
    if current_stage["status"] == "invalidated":
        print("Probe changed the captured task write scope; preserve the files and reconcile before continuing.", file=sys.stderr)
        return 2
    return result


def load_intent(value):
    try:
        intent = json.loads(Path(value).read_text())
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise RouteError(f"cannot read finalization intent: {error}") from error
    if not isinstance(intent, dict) or intent.get("schema_version") != 1:
        raise RouteError("finalization intent must be a schema-v1 JSON object")
    return intent


def validate_finalization_intent(intent):
    required = {"claim_id", "role", "work_item", "route", "repo", "expected_head", "outcome", "report", "checkpoint", "commit"}
    if not required.issubset(intent):
        raise RouteError("finalization intent is missing required fields")
    if not isinstance(intent["role"], str) or intent["role"] not in ROLE_MODES:
        raise RouteError("finalization intent has an unsupported role")
    string_fields = ("claim_id", "work_item", "route", "repo", "expected_head")
    if any(not isinstance(intent.get(name), str) for name in string_fields):
        raise RouteError("finalization claim, route, repository, and head fields must be strings")
    if not isinstance(intent["outcome"], str) or intent["outcome"] not in {"accepted", "failed", "worker_failed", "needs_context", "rejected"}:
        raise RouteError("finalization outcome must be accepted, failed, worker_failed, needs_context, or rejected")
    validate_work_item(intent["work_item"])
    if not re.fullmatch(r"[0-9a-f]{32}", intent["claim_id"]):
        raise RouteError("finalization intent has an invalid claim ID")
    if not re.fullmatch(r"(?:[0-9a-f]{40}|[0-9a-f]{64})", intent["expected_head"]):
        raise RouteError("finalization intent has an invalid repository head")
    if not isinstance(intent["report"], dict) or not isinstance(intent["commit"], dict):
        raise RouteError("report and commit intent entries must be objects")
    if set(intent["report"]) != {"source", "sha256"} or not isinstance(intent["report"]["source"], str):
        raise RouteError("report intent must contain only a source path and digest")
    if not isinstance(intent["report"]["sha256"], str) or not re.fullmatch(r"[0-9a-f]{64}", intent["report"]["sha256"]):
        raise RouteError("report intent has an invalid SHA-256 digest")
    checkpoint = intent["checkpoint"]
    if checkpoint is not None:
        if not isinstance(checkpoint, dict) or set(checkpoint) != {"path", "expected_sha256", "content"}:
            raise RouteError("checkpoint intent must contain path, expected digest, and content")
        if (not isinstance(checkpoint["path"], str)
                or not isinstance(checkpoint["expected_sha256"], str)
                or not re.fullmatch(r"[0-9a-f]{64}", checkpoint["expected_sha256"])
                or not isinstance(checkpoint["content"], str)):
            raise RouteError("checkpoint intent uses invalid path, digest, or content types")
    if set(intent["commit"]) != {"enabled", "message", "paths"}:
        raise RouteError("commit intent must contain only enabled, message, and paths")
    if not isinstance(intent["commit"].get("enabled"), bool):
        raise RouteError("commit intent must explicitly enable or disable the commit")
    if not isinstance(intent["commit"].get("message"), str) or not isinstance(intent["commit"].get("paths"), list):
        raise RouteError("commit message and paths must use their fixed types")
    if intent["commit"]["enabled"] and intent["outcome"] != "accepted":
        raise RouteError("only an accepted result can authorize a task commit")


def approved_commit_entries(repo, claim, commit):
    paths = commit.get("paths")
    if not isinstance(paths, list) or not paths:
        raise RouteError("enabled commit must list exact task paths")
    baseline = {item["path"]: item for item in claim["write_paths"]}
    reviewed = {item["path"]: item for item in claim["stages"]["run"].get("post_baseline", [])}
    saved_entries = claim.get("pending_commit_entries")
    check_filemode = git_output(repo, "config", "--type=bool", "--default=true", "--get", "core.filemode").stdout.strip() == "true"
    entries = {}
    for item in paths:
        if not isinstance(item, dict) or set(item) != {"path", "sha256"}:
            raise RouteError("commit paths must contain only path and sha256")
        relative = item["path"]
        if not isinstance(relative, str) or Path(relative).is_absolute() or ".." in Path(relative).parts:
            raise RouteError("commit path must be a repository-relative task path")
        if relative not in baseline or not baseline[relative]["clean_at_claim"]:
            raise RouteError("commit path was not cleanly captured at claim time; reconcile before committing")
        executable = reviewed.get(relative, {}).get("worktree_executable")
        if type(executable) is not bool:
            raise RouteError("reviewed task path lacks worktree mode evidence")
        path = repo_file(repo, relative, "commit task path")
        content = path.read_bytes()
        if hashlib.sha256(content).hexdigest() != item["sha256"]:
            raise RouteError(f"task path changed after result review: {relative}")
        if relative in entries:
            raise RouteError("approved commit paths must be unique")
        if saved_entries is None:
            blob = git_output_bytes(repo, "hash-object", f"--path={relative}", "--stdin", input_bytes=content)
            index_entry = baseline[relative]["index_entry"]
            if check_filemode or not index_entry:
                mode = "100755" if check_filemode and executable else "100644"
            else:
                mode = index_entry.split()[0]
            entries[relative] = {"mode": mode, "oid": blob.stdout.decode("ascii").strip()}
        else:
            entries[relative] = saved_entries.get(relative)
    if saved_entries is not None and (entries != saved_entries or any(not entry for entry in entries.values())):
        raise RouteError("saved Git entries do not match the pending intent")
    return entries


def index_matches_commit_entry(repo, relative, entry):
    index = git_output(repo, "ls-files", "--stage", "-z", "--", relative).stdout.rstrip("\0")
    return "\0" not in index and index.partition("\t")[0] == f"{entry['mode']} {entry['oid']} 0"


def stage_approved_commit(repo, entries, message, expected_head):
    current_head = git_output(repo, "rev-parse", "HEAD").stdout.strip()
    if current_head != expected_head:
        return recover_commit(repo, expected_head, entries)
    paths_only = sorted(entries)
    git_output(repo, "add", "--", *paths_only)
    for relative, entry in entries.items():
        if not index_matches_commit_entry(repo, relative, entry):
            raise RouteError("task index differs from the pending commit intent")
    if git_output(repo, "rev-parse", "HEAD").stdout.strip() != expected_head:
        raise RouteError("repository head moved before task commit; claim remains pending")
    git_output(repo, "commit", "--only", "-m", message, "--", *paths_only)
    return recover_commit(repo, expected_head, entries)


def recover_commit(repo, expected_head, entries):
    current_head = git_output(repo, "rev-parse", "HEAD").stdout.strip()
    parents = git_output(repo, "rev-list", "--parents", "-n", "1", current_head).stdout.split()
    if len(parents) != 2 or parents[1] != expected_head:
        raise RouteError("repository moved since finalization began; claim remains pending")
    changed = git_output(repo, "diff-tree", "--no-commit-id", "--name-only", "-z", "-r", expected_head, current_head).stdout.rstrip("\0").split("\0")
    if sorted(changed) != sorted(entries):
        raise RouteError("existing commit does not match the pending finalization intent")
    for relative, entry in entries.items():
        tree = git_output(repo, "ls-tree", "-z", current_head, "--", relative).stdout
        if tree.partition("\t")[0] != f"{entry['mode']} blob {entry['oid']}":
            raise RouteError("existing commit tree entry does not match the pending finalization intent")
        if not index_matches_commit_entry(repo, relative, entry) or git_output(
            repo, "status", "--porcelain=v1", "--", relative,
        ).stdout.strip():
            raise RouteError("existing commit is not reflected in the task index and worktree")
    return current_head


def apply_checkpoint(repo, checkpoint):
    if set(checkpoint) != {"path", "expected_sha256", "content"}:
        raise RouteError("checkpoint intent must contain path, expected_sha256, and content")
    path, desired_bytes, desired_digest, current_digest = inspect_checkpoint(repo, checkpoint)
    if current_digest == desired_digest:
        return desired_digest
    atomic_write(path, desired_bytes, path.stat().st_mode & 0o777)
    return desired_digest


def inspect_checkpoint(repo, checkpoint):
    if set(checkpoint) != {"path", "expected_sha256", "content"}:
        raise RouteError("checkpoint intent must contain path, expected_sha256, and content")
    path = repo_file(repo, checkpoint["path"], "checkpoint path")
    state_root = canonical_directory(repo / "docs/features/.feature-states", "workflow state directory")
    if not is_within(path, state_root):
        raise RouteError("workflow checkpoint must stay under docs/features/.feature-states")
    desired = checkpoint["content"]
    if not isinstance(desired, str) or len(desired) > 65536:
        raise RouteError("checkpoint content must be a string no larger than 64 KiB")
    desired_bytes = desired.encode()
    desired_digest = hashlib.sha256(desired_bytes).hexdigest()
    current_bytes = path.read_bytes()
    current_digest = hashlib.sha256(current_bytes).hexdigest()
    if current_digest not in {desired_digest, checkpoint["expected_sha256"]}:
        raise RouteError("workflow checkpoint changed; claim remains pending")
    return path, desired_bytes, desired_digest, current_digest


def promote_report(attempt_dir, report_intent, outcome):
    source, digest = inspect_report(attempt_dir, report_intent)
    name = "accepted-report.md" if outcome == "accepted" else "terminal-report.md"
    destination = attempt_dir / name
    if destination.exists():
        if hashlib.sha256(destination.read_bytes()).hexdigest() != digest:
            raise RouteError("accepted report differs from pending intent")
    else:
        atomic_write(destination, source.read_bytes())
    return destination


def inspect_report(attempt_dir, report_intent):
    if set(report_intent) != {"source", "sha256"}:
        raise RouteError("report intent must contain only source and sha256")
    source = canonical_file(report_intent["source"], "worker report")
    if not is_within(source, attempt_dir):
        raise RouteError("worker report must stay inside its attempt directory")
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    if digest != report_intent["sha256"]:
        raise RouteError("worker report changed after acceptance")
    return source, digest


def validate_run_evidence(repo, claim, report_source, report_digest, entries, pending):
    run_stage = claim.get("stages", {}).get("run")
    if (not run_stage or run_stage.get("status") != "complete" or run_stage.get("exit_status") != 0
            or run_stage.get("report_path") != str(report_source)
            or run_stage.get("report_sha256") != report_digest):
        raise RouteError("worker outcome requires the matching completed run and live report evidence")
    current_head = git_output(repo, "rev-parse", "HEAD").stdout.strip()
    if current_head != claim["head_sha"] and not (pending and entries):
        raise RouteError("repository head changed before finalization")
    before = run_stage.get("post_baseline")
    current = [file_state(repo, item["path"]) for item in claim["write_paths"]]
    if not isinstance(before, list) or len(before) != len(current):
        raise RouteError("completed run lacks its full write-scope evidence")
    for recorded, live in zip(before, current):
        if recorded == live:
            continue
        if (not pending or live["path"] not in entries or recorded["path"] != live["path"]
                or recorded["exists"] != live["exists"]
                or recorded.get("worktree_executable") != live["worktree_executable"]
                or recorded["content_sha256"] != live["content_sha256"]):
            raise RouteError("reviewed write-scope evidence changed; reconcile before finalizing")
        if current_head == claim["head_sha"]:
            if not index_matches_commit_entry(repo, live["path"], entries[live["path"]]):
                raise RouteError("task index differs from the pending commit intent")


def finalize_attempt(intent_path):
    intent = load_intent(intent_path)
    validate_finalization_intent(intent)
    repo = canonical_directory(intent["repo"], "repository")
    routing_root = routing_root_for(repo)
    claim_path = claim_file_for(routing_root, intent["role"], intent["work_item"])
    with work_item_lock(routing_root, intent["role"], intent["work_item"]):
        try:
            claim = json.loads(claim_path.read_text())
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            raise RouteError(f"cannot read active claim: {error}") from error
        if claim.get("claim_id") != intent["claim_id"] or claim.get("route") != intent["route"] or claim.get("repo") != str(repo):
            raise RouteError("finalization intent does not match the current claim and saved route")
        if claim.get("head_sha") != intent["expected_head"]:
            raise RouteError("finalization intent does not match the saved repository baseline")
        attempt_dir = canonical_directory(claim["attempt_dir"], "attempt directory")
        canonical_intent = canonical_file(intent_path, "finalization intent")
        if not is_within(canonical_intent, attempt_dir):
            raise RouteError("finalization intent must stay inside its attempt directory")
        identity = hashlib.sha256(json.dumps(intent, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        pending = claim.get("pending_finalization")
        if pending and pending != identity:
            raise RouteError("a different finalization intent is already pending")
        if claim.get("state") == "finalized":
            if claim.get("finalization_sha256") != identity:
                raise RouteError("attempt already has a different terminal disposition")
            print(json.dumps({"status": claim["state"], "recovered": True, "claim_id": claim["claim_id"], "commit": claim.get("commit_id")}))
            return 0
        if claim.get("state") == "stopped":
            if claim.get("finalization_sha256") != identity:
                raise RouteError("attempt already has a different terminal disposition")
            print(json.dumps({"status": "stopped", "recovered": True, "claim_id": claim["claim_id"]}))
            return 0
        if any(stage.get("status") == "consumed" for stage in claim.get("stages", {}).values()):
            raise RouteError("a consumed launch lacks terminal evidence; keep the claim pending")
        report_source, report_digest = inspect_report(attempt_dir, intent["report"])
        checkpoint = intent["checkpoint"]
        if checkpoint is not None:
            inspect_checkpoint(repo, checkpoint)
        commit_intent = intent["commit"]
        entries = {}
        if commit_intent["enabled"]:
            if intent["role"] != "implementer":
                raise RouteError("only an implementer finalization can commit task paths")
            if not commit_intent["message"].strip() or len(commit_intent["message"]) > 500:
                raise RouteError("approved commit message must be a non-empty string of at most 500 characters")
            run = claim.get("stages", {}).get("run", {})
            if run.get("status") == "complete":
                entries = approved_commit_entries(repo, claim, commit_intent)
        if intent["outcome"] != "failed":
            validate_run_evidence(repo, claim, report_source, report_digest, entries, pending)
        elif claim.get("stages", {}).get("run", {}).get("status") == "complete":
            raise RouteError("a completed run requires a worker outcome instead of a transport failure")
        claim["state"] = "pending-finalization"
        claim["pending_finalization"] = identity
        if entries:
            claim["pending_commit_entries"] = entries
        for stage in claim.get("stages", {}).values():
            if stage.get("status") == "ready":
                stage["status"] = "cancelled"
        write_json(claim_path, claim)
        if entries:
            commit_id = stage_approved_commit(repo, entries, commit_intent["message"], intent["expected_head"])
        else:
            commit_id = None
        report = promote_report(attempt_dir, intent["report"], intent["outcome"])
        checkpoint_digest = apply_checkpoint(repo, checkpoint) if checkpoint is not None else None
        claim.update({
            "state": "finalized" if intent["outcome"] == "accepted" else "stopped",
            "outcome": intent["outcome"],
            "finalization_sha256": identity,
            "terminal_report": str(report),
            "report_sha256": intent["report"]["sha256"],
            "commit_id": commit_id,
            "checkpoint_path": checkpoint["path"] if checkpoint is not None else None,
            "checkpoint_sha256": checkpoint_digest,
        })
        write_json(claim_path, claim)
    print(json.dumps({"status": claim["state"], "recovered": False, "claim_id": claim["claim_id"], "commit": commit_id, "report": str(report)}))
    return 0


def is_within(path, parent):
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def role_permissions(args, repo, routing_root):
    expected_mode = ROLE_MODES.get(args.role)
    if expected_mode is None:
        raise RouteError(f"unsupported role {args.role!r}")
    if args.sandbox != expected_mode:
        raise RouteError(f"role {args.role!r} requires sandbox mode {expected_mode!r}")
    if args.role == "implementer" and not args.write_path:
        raise RouteError(f"{args.role} requires at least one authorized --write-path")
    if expected_mode == "read-only" and args.write_path:
        raise RouteError(f"role {args.role!r} cannot receive workspace write paths")
    authorized = []
    protected = [repo / ".git", repo / ".dev-flow", repo / "docs/features/.feature-states", routing_root]
    protected.extend(Path(path).absolute() for path in args.protected_path)
    protected.extend(Path(path).resolve() for path in args.protected_path)
    protected.extend(git_admin_paths(repo))
    for value in args.write_path:
        candidate = Path(value)
        path = canonical_file(candidate, "authorized write path") if candidate.exists() else canonical_new_file(candidate, repo)
        if not is_within(path, repo):
            raise RouteError("authorized write paths must stay inside the repository")
        if any(is_within(path, root) or path == root for root in protected):
            raise RouteError(f"authorized write path overlaps a protected coordinator path: {path}")
        if any(part in {".git", ".dev-flow", ".feature-states"} for part in path.parts):
            raise RouteError(f"authorized write path overlaps protected workflow data: {path}")
        authorized.append(path)
    return expected_mode, sorted(set(authorized)), protected


def git_admin_paths(repo):
    protected = []
    for option in ("--absolute-git-dir", "--git-common-dir"):
        try:
            result = subprocess.run(
                ["git", "-C", str(repo), "rev-parse", "--path-format=absolute", option],
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError:
            return protected
        if result.returncode == 0 and result.stdout.strip():
            path = Path(result.stdout.strip())
            protected.extend((path, path.resolve()))
    return protected


def declared_environment(config, adapter):
    all_settings = config.get("cli_adapter_settings", {})
    if not isinstance(all_settings, dict):
        raise RouteError("cli_adapter_settings must be a JSON object")
    settings = all_settings.get(adapter, {})
    if not isinstance(settings, dict):
        raise RouteError(f"settings for adapter {adapter!r} must be a JSON object")
    for key in ("environment", "credentials", "forbidden_environment", "files"):
        if key not in settings:
            raise RouteError(f"adapter settings must explicitly declare {key}")
    names = settings.get("environment", [])
    credentials = settings.get("credentials", [])
    forbidden = settings.get("forbidden_environment", [])
    files = settings.get("files", [])
    if not isinstance(names, list) or not all(isinstance(name, str) for name in names):
        raise RouteError("declared environment settings must be a list of names")
    if not isinstance(credentials, list) or not all(isinstance(name, str) for name in credentials):
        raise RouteError("declared credential environment must be a list of names")
    if not isinstance(forbidden, list) or not all(isinstance(name, str) for name in forbidden):
        raise RouteError("forbidden environment overrides must be a list of names")
    if not isinstance(files, list) or not all(isinstance(path, str) for path in files):
        raise RouteError("declared setting files must be a list of paths")
    for name in names:
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name) or SECRET_SETTING.search(name):
            raise RouteError(f"declared setting {name!r} is invalid or secret; keep credentials in the approved auth environment")
    for name in credentials:
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            raise RouteError(f"declared credential name {name!r} is invalid")
    for name in forbidden:
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            raise RouteError(f"forbidden environment name {name!r} is invalid")
        if name in os.environ:
            raise RouteError(f"disabled model or sandbox override {name} blocks this adapter route")
    if any(BLOCKED_SETTING.search(name) for name in names):
        raise RouteError("model and sandbox overrides are disabled; remove them from cli_adapter_settings")
    if set(names).intersection(credentials) or set(forbidden).intersection(names) or set(forbidden).intersection(credentials):
        raise RouteError("declared settings, credentials, and disabled overrides must use separate names")
    return settings, names, credentials, files


def sha256_bytes(value):
    return hashlib.sha256(value).hexdigest()


def effective_settings(config, adapter, runtime_home="", runtime_tmp=""):
    _, names, credentials, files = declared_environment(config, adapter)
    environment_identity = {}
    fixed_path = f"{Path(sys.executable).parent}:/usr/bin:/bin:/usr/sbin:/sbin"
    child_environment = {
        "PATH": fixed_path,
        "HOME": str(runtime_home),
        "TMPDIR": str(runtime_tmp),
        "LANG": "C.UTF-8",
    }
    for name in (*names, *credentials):
        if name in child_environment:
            raise RouteError(f"fixed runtime setting {name} cannot be declared as an environment setting or credential")
    for name in credentials:
        if name in os.environ:
            child_environment[name] = os.environ[name]
    for name in names:
        if name in os.environ:
            value = os.environ[name]
            child_environment[name] = value
            environment_identity[name] = sha256_bytes(value.encode())
    file_identity = {}
    for value in files:
        path = canonical_file(value, "declared setting file")
        try:
            file_identity[str(path)] = sha256_bytes(path.read_bytes())
        except OSError as error:
            raise RouteError(f"cannot read declared setting file {path}: {error}") from error
    return child_environment, {
        "environment": environment_identity,
        "files": file_identity,
        "runtime_policy": "isolated-home-temp-v1",
        "path": sha256_bytes(child_environment["PATH"].encode()),
    }


def configuration_identity(config, adapter):
    adapters = config.get("cli_adapters", {})
    executable = adapters.get(adapter) if isinstance(adapters, dict) else None
    if not isinstance(executable, str):
        raise RouteError(f"adapter {adapter!r} is not configured with an executable path")
    all_settings = config.get("cli_adapter_settings", {})
    if not isinstance(all_settings, dict):
        raise RouteError("cli_adapter_settings must be a JSON object")
    material = {
        "executable": executable,
        "settings": all_settings.get(adapter, {}),
    }
    return sha256_bytes(json.dumps(material, sort_keys=True, separators=(",", ":")).encode())


def adapter_identity(resolution, configuration_digest, settings):
    material = {"resolution": resolution, "configuration_sha256": configuration_digest, "settings": settings}
    return sha256_bytes(json.dumps(material, sort_keys=True, separators=(",", ":")).encode())


def require_adapter_identity(expected, actual):
    if expected is not None and expected != actual:
        raise RouteError("adapter identity changed since the review batch was pinned")


def identify_adapter(args):
    lane = parse_custom_lane(args.lane)
    if lane is None or lane[0] == "codex":
        raise RouteError("adapter identity requires a configured custom CLI route")
    config = read_config(args.config)
    resolution = resolve_custom_route(config, args.lane, *lane)
    _, settings = effective_settings(config, lane[0])
    digest = adapter_identity(resolution, configuration_identity(config, lane[0]), settings)
    require_adapter_identity(args.expected_identity, digest)
    return {"route": args.lane, "identity_sha256": digest}


def sandbox_profile(writable_paths, report_dir, runtime_tmp, protected_paths, routing_root):
    writable_paths = [Path(path).resolve() for path in writable_paths]
    scratch_dirs = [Path(runtime_tmp).resolve(strict=True)]
    if report_dir is not None:
        scratch_dirs.append(Path(report_dir).resolve(strict=True))
    protected_paths = sorted({Path(path).resolve() for path in (*protected_paths, routing_root)})
    lines = [
        "(version 1)",
        '(import "system.sb")',
        "(deny default)",
        "(allow process*)",
        "(allow file-read*)",
        "(allow sysctl-read)",
        "(allow network-outbound)",
    ]
    for path in writable_paths:
        lines.append(f"(allow file-write-create file-write-data (literal {json.dumps(str(path))}))")
    for directory in scratch_dirs:
        lines.append(f"(allow file-write-create (subpath {json.dumps(str(directory))}))")
        lines.append(f"(allow file-write-data (subpath {json.dumps(str(directory))}))")
        lines.append(f"(deny file-write* (literal {json.dumps(str(directory))}))")
    for path in protected_paths:
        lines.append(f"(deny file-write* (literal {json.dumps(str(path))}))")
        if path.is_dir() and path != Path(routing_root).resolve():
            lines.append(f"(deny file-write* (subpath {json.dumps(str(path))}))")
    return "\n".join(lines) + "\n"


def verify_sandbox(routing_root):
    if sys.platform != "darwin" or not SANDBOX_EXEC.is_file() or not routing_root.is_dir():
        raise RouteError("the macOS sandbox-exec boundary or protected docs/features/.routing directory is unavailable")
    with tempfile.TemporaryDirectory(prefix="dev-flow-sandbox-check-", dir=str(routing_root)) as directory:
        root = Path(directory)
        allowed = root / "allowed.txt"
        protected = root / "protected.txt"
        report_dir = root / "report"
        runtime_tmp = root / "tmp"
        report_dir.mkdir()
        runtime_tmp.mkdir()
        allowed.write_text("before\n")
        protected.write_text("protected\n")
        redirect = root / "protected-link"
        redirect.symlink_to(protected)
        new_allowed = root / "new-allowed.txt"
        profile = sandbox_profile([allowed, new_allowed], report_dir, runtime_tmp, [protected], routing_root)
        profile_path = root / "check.sb"
        profile_path.write_text(profile)
        probe = "printf changed > \"$1\" && printf created > \"$5\" && printf report > \"$2/check.md\" && if printf denied > \"$3\" 2>/dev/null; then exit 9; fi && if printf denied > \"$4\" 2>/dev/null; then exit 10; fi && if printf denied > \"$6\" 2>/dev/null; then exit 11; fi"
        result = subprocess.run(
            [str(SANDBOX_EXEC), "-f", str(profile_path), "/bin/sh", "-c", probe, "sandbox-check", str(allowed), str(report_dir), str(protected), str(redirect), str(new_allowed), str(root / "new-denied.txt")],
            capture_output=True,
            timeout=5,
            check=False,
        )
        if result.returncode != 0 or allowed.read_text() != "changed" or protected.read_text() != "protected\n" or not (report_dir / "check.md").is_file():
            detail = result.stderr.decode(errors="replace").strip() or f"sandbox fixture exited {result.returncode}"
            raise RouteError(f"sandbox enforcement verification failed; refusing adapter launch: {detail}")
        termination = subprocess.Popen(["/bin/sleep", "30"], start_new_session=True)
        try:
            os.killpg(termination.pid, signal.SIGTERM)
            termination.wait(timeout=2)
        except (OSError, subprocess.TimeoutExpired) as error:
            try:
                os.killpg(termination.pid, signal.SIGKILL)
            except OSError:
                pass
            raise RouteError(f"process-group termination verification failed: {error}") from error


def validate_receipt_path(value, must_exist, report_dir, routing_root):
    path = Path(value)
    if path.is_symlink():
        raise RouteError("controller receipt cannot be a symlink")
    parent = canonical_directory(path.parent, "controller receipt directory")
    if parent.stat().st_uid != os.getuid() or parent.stat().st_mode & 0o077:
        raise RouteError("controller receipt directory must be private and owned by the controller")
    resolved = parent / path.name
    if not is_within(resolved, routing_root):
        raise RouteError("controller receipt must stay under protected docs/features/.routing")
    if is_within(resolved, report_dir):
        raise RouteError("controller receipt must stay outside the worker report directory")
    if must_exist:
        file_path = canonical_file(resolved, "controller receipt")
        if file_path.stat().st_mode & 0o077:
            raise RouteError("controller receipt permissions must be private")
    elif resolved.exists():
        raise RouteError("controller receipt already exists; use a fresh controller path")
    return resolved


def validate_report_path(value, routing_root):
    path = Path(value)
    if path.is_symlink():
        raise RouteError("worker report cannot be a symlink")
    parent = canonical_directory(path.parent, "dedicated report directory")
    if not parent.name.startswith("dev-flow-report-") or parent.stat().st_uid != os.getuid() or parent.stat().st_mode & 0o077:
        raise RouteError("worker report directory must be a private, controller-created dev-flow-report-* directory")
    resolved = parent / path.name
    if not is_within(resolved, routing_root):
        raise RouteError("worker report must stay under docs/features/.routing")
    return resolved, parent


def launch_argv(action, resolution, args, mode, settings_digest, metadata_fd, write_paths):
    argv = [
        resolution["executable"], action,
        "--model", resolution["model"], "--repo", str(args.repo),
        "--sandbox", mode, "--role", args.role,
        "--metadata-fd", str(metadata_fd), "--settings-sha256", settings_digest,
    ]
    if action == "run":
        argv.extend(("--brief", str(args.brief)))
    for path in write_paths:
        argv.extend(("--write-path", str(path)))
    argv.extend(("--report", str(args.report)))
    return argv


class MetadataPipeReader(threading.Thread):
    def __init__(self, read_fd):
        super().__init__(daemon=True)
        self.read_fd = read_fd
        self.content = bytearray()
        self.overflow = False
        self.error = None

    def run(self):
        try:
            while True:
                chunk = os.read(self.read_fd, 8192)
                if not chunk:
                    break
                if len(self.content) + len(chunk) <= MAX_METADATA_BYTES:
                    self.content.extend(chunk)
                else:
                    self.overflow = True
        except OSError as error:
            self.error = error
        finally:
            os.close(self.read_fd)


def read_metadata(reader):
    reader.join(timeout=5)
    if reader.is_alive():
        raise RouteError("adapter left the metadata channel open after exit")
    if reader.error:
        raise RouteError(f"cannot read backend metadata: {reader.error}")
    content = reader.content
    if not content or reader.overflow:
        raise RouteError("adapter did not return bounded schema-v1 backend metadata")
    try:
        metadata = json.loads(content)
    except (UnicodeError, json.JSONDecodeError) as error:
        raise RouteError(f"adapter returned malformed backend metadata: {error}") from error
    if not isinstance(metadata, dict):
        raise RouteError("backend metadata must be a JSON object")
    return metadata


def stop_remaining_process_group(process_id):
    try:
        os.killpg(process_id, 0)
    except ProcessLookupError:
        return False
    except OSError as error:
        raise RouteError(f"cannot verify adapter process-group termination: {error}") from error
    try:
        os.killpg(process_id, signal.SIGTERM)
        time.sleep(0.1)
        os.killpg(process_id, signal.SIGKILL)
    except ProcessLookupError:
        return True
    except OSError as error:
        raise RouteError(f"cannot terminate adapter child process group: {error}") from error
    return True


def validate_metadata(metadata, resolution, args, mode, settings_digest, expected_source=None, expected_backend=None):
    expected = {
        "schema_version": 1,
        "observed_model_id": resolution["model"],
        "role": args.role,
        "permission_mode": mode,
        "settings_sha256": settings_digest,
    }
    for name, value in expected.items():
        observed = metadata.get(name)
        if type(observed) is not type(value) or observed != value:
            raise RouteError(f"backend metadata mismatch for {name}; expected the selected route and enforced permission mode")
    source = metadata.get("model_id_source")
    if not isinstance(source, str) or source not in {"backend-response", "backend-event"}:
        raise RouteError("backend metadata must name an authoritative backend-response or backend-event source")
    if not isinstance(metadata.get("backend_id"), str) or not metadata["backend_id"].strip():
        raise RouteError("backend metadata must identify its source backend")
    if expected_source is not None and source != expected_source:
        raise RouteError("backend metadata source changed after probe")
    if expected_backend is not None and metadata["backend_id"] != expected_backend:
        raise RouteError("backend identity changed after probe")
    return metadata


def invoke_adapter(action, args, record_launch, expected_identity):
    lane = parse_custom_lane(args.lane)
    if lane is None:
        raise RouteError("custom adapter invocation requires cli:<adapter>/<model>")
    adapter, _ = lane
    if adapter == "codex":
        raise RouteError("the built-in Codex route does not use a custom adapter")
    config = read_config(args.config)
    resolution = resolve_custom_route(config, args.lane, *lane)
    executable = Path(resolution["executable"])
    if sha256_bytes(executable.read_bytes()) != resolution["sha256"]:
        raise RouteError("adapter executable changed during resolution")
    repo = canonical_directory(args.repo, "repository")
    args.repo = repo
    routing_root = routing_root_for(repo)
    mode, write_paths, protected_paths = role_permissions(args, repo, routing_root)
    report, report_dir = validate_report_path(args.report, routing_root)
    args.report = report
    receipt_path = validate_receipt_path(args.receipt, action == "run", report_dir, routing_root)
    if action == "run":
        args.brief = canonical_file(args.brief, "worker brief")
    if report.exists():
        raise RouteError("worker report destination already exists; use a fresh dedicated report path")
    config_hash = configuration_identity(config, adapter)
    if sys.platform != "darwin" or not routing_root.is_dir():
        raise RouteError("the supported macOS sandbox boundary and docs/features/.routing are required")
    with tempfile.TemporaryDirectory(prefix="dev-flow-adapter-", dir=str(routing_root)) as runtime_dir:
        runtime_root = Path(runtime_dir)
        runtime_home = runtime_root / "home"
        runtime_tmp = runtime_root / "tmp"
        runtime_home.mkdir()
        runtime_tmp.mkdir()
        environment, settings = effective_settings(config, adapter, runtime_home, runtime_tmp)
        if expected_identity is not None:
            require_adapter_identity(expected_identity, adapter_identity(resolution, config_hash, settings))
        settings_digest = sha256_bytes(json.dumps(settings, sort_keys=True, separators=(",", ":")).encode())
        receipt = {
            "schema_version": 1,
            "route": args.lane,
            "adapter": adapter,
            "executable": resolution["executable"],
            "executable_sha256": resolution["sha256"],
            "model": resolution["model"],
            "repo": str(repo),
            "role": args.role,
            "permission_mode": mode,
            "write_paths": [str(path) for path in write_paths],
            "report": str(report),
            "settings_sha256": settings_digest,
            "configuration_sha256": config_hash,
            "observed_model_id": resolution["model"],
        }
        previous = None
        if action == "run":
            try:
                previous = json.loads(receipt_path.read_text())
            except (OSError, UnicodeError, json.JSONDecodeError) as error:
                raise RouteError(f"cannot read valid probe receipt: {error}") from error
            provenance = {"model_id_source": previous.get("model_id_source"), "backend_id": previous.get("backend_id")}
            previous_identity = {key: value for key, value in previous.items() if key not in provenance}
            if previous_identity != receipt or not all(provenance.values()):
                raise RouteError("adapter, model, or effective settings changed after probe")
        writable_paths = write_paths
        writable_report_dir = report_dir if action == "run" and args.role != "reviewer" else None
        profile = sandbox_profile(writable_paths, writable_report_dir, runtime_tmp, protected_paths, routing_root)
        verify_sandbox(routing_root)
        timed_out = False
        with tempfile.NamedTemporaryFile("w", suffix=".sb", encoding="utf-8", dir=str(runtime_root)) as profile_file:
            profile_file.write(profile)
            profile_file.flush()
            latest_config = read_config(args.config)
            if configuration_identity(latest_config, adapter) != config_hash:
                raise RouteError("adapter settings changed before launch")
            if sha256_bytes(executable.read_bytes()) != resolution["sha256"]:
                raise RouteError("adapter executable changed before launch")
            _, latest_settings = effective_settings(latest_config, adapter, runtime_home, runtime_tmp)
            if latest_settings != settings:
                raise RouteError("adapter effective settings changed before launch")
            read_fd, write_fd = os.pipe()
            argv = launch_argv(action, resolution, args, mode, settings_digest, write_fd, write_paths)
            try:
                process = subprocess.Popen(
                    [str(SANDBOX_EXEC), "-f", profile_file.name, *argv],
                    cwd=repo,
                    env=environment,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    pass_fds=(write_fd,),
                    start_new_session=True,
                )
            except OSError as error:
                os.close(read_fd)
                os.close(write_fd)
                raise RouteError(f"cannot start the sandboxed adapter: {error}") from error
            os.close(write_fd)
            try:
                record_launch(process.pid)
            except (RouteError, OSError):
                os.close(read_fd)
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                finally:
                    process.communicate(timeout=5)
                raise
            metadata_reader = MetadataPipeReader(read_fd)
            metadata_reader.start()
            try:
                stdout, stderr = process.communicate(timeout=INVOCATION_TIMEOUT_SECONDS)
            except subprocess.TimeoutExpired:
                timed_out = True
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    stdout, stderr = process.communicate(timeout=2)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    stdout, stderr = process.communicate()
        try:
            left_children = stop_remaining_process_group(process.pid)
        finally:
            if stdout:
                (sys.stderr if action == "probe" else sys.stdout).buffer.write(stdout)
            if stderr:
                sys.stderr.buffer.write(stderr)
        if timed_out or left_children:
            metadata_reader.join(timeout=5)
            if timed_out:
                print("Adapter invocation exceeded its time limit and was terminated.", file=sys.stderr)
                return 124
            print("Adapter left a child process running after exit; it was terminated.", file=sys.stderr)
            return 2
        if process.returncode != 0:
            print(f"Adapter exited with status {process.returncode}; backend result is not accepted.", file=sys.stderr)
            return process.returncode if 1 <= process.returncode <= 255 else 1
        try:
            metadata = read_metadata(metadata_reader)
            validate_metadata(
                metadata,
                resolution,
                args,
                mode,
                settings_digest,
                expected_source=previous.get("model_id_source") if previous else None,
                expected_backend=previous.get("backend_id") if previous else None,
            )
        except RouteError as error:
            print(f"Cannot accept adapter metadata: {error}.", file=sys.stderr)
            return 2
        if action == "probe":
            receipt["model_id_source"] = metadata["model_id_source"]
            receipt["backend_id"] = metadata["backend_id"]
            descriptor = os.open(receipt_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(descriptor, "w") as output:
                json.dump(receipt, output, sort_keys=True)
            print(json.dumps({"status": "probed", "model": metadata["observed_model_id"], "receipt": str(receipt_path)}))
            return 0
        if args.role == "reviewer":
            if args.report.exists() or args.report.is_symlink() or not stdout.strip():
                raise RouteError("reviewer requires fresh report output captured by the controller")
            atomic_write(args.report, stdout)
        return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    resolve_parser = subparsers.add_parser("resolve", help="resolve a CLI lane")
    resolve_parser.add_argument("--config", required=True)
    resolve_parser.add_argument("--lane", required=True)
    identify_parser = subparsers.add_parser("identify", help="record or recheck a custom adapter identity")
    identify_parser.add_argument("--config", required=True)
    identify_parser.add_argument("--lane", required=True)
    identify_parser.add_argument("--expected-identity")
    claim_parser = subparsers.add_parser("claim", help="claim one role work item and capture its write baseline")
    claim_parser.add_argument("--config", required=True)
    claim_parser.add_argument("--repo", required=True)
    claim_parser.add_argument("--role", required=True, choices=tuple(ROLE_MODES))
    claim_parser.add_argument("--work-item", required=True)
    claim_parser.add_argument("--lane", required=True)
    claim_parser.add_argument("--write-path", action="append", default=[])
    claim_parser.add_argument("--retry-claim", help="explicitly retry a reconciled failed claim on its saved route")
    claim_parser.add_argument("--expected-identity", help="pin the reviewer claim to the saved review batch identity")
    finalize_parser = subparsers.add_parser("finalize", help="apply or recover one approved attempt disposition")
    finalize_parser.add_argument("--intent", required=True)
    for command in ("authorize-stage", "bind-driver", "release-driver", "settle-stage"):
        control_parser = subparsers.add_parser(command)
        control_parser.add_argument("--repo", required=True)
        control_parser.add_argument("--role", required=True, choices=tuple(ROLE_MODES))
        control_parser.add_argument("--work-item", required=True)
        control_parser.add_argument("--claim-id", required=True)
        control_parser.add_argument("--stage", required=True, choices=("probe", "run"))
        if command != "authorize-stage":
            control_parser.add_argument("--authorization-id", required=True)
        if command in ("bind-driver", "release-driver"):
            control_parser.add_argument("--handle", required=True, type=int)
    driver_parser = subparsers.add_parser("driver", help="wait for coordinator binding and release before one launch")
    driver_parser.add_argument("--config", required=True)
    driver_parser.add_argument("--lane", required=True)
    driver_parser.add_argument("--repo", required=True)
    driver_parser.add_argument("--role", required=True, choices=tuple(ROLE_MODES))
    driver_parser.add_argument("--sandbox", required=True, choices=("workspace-write", "read-only"))
    driver_parser.add_argument("--report", required=True)
    driver_parser.add_argument("--receipt", required=True)
    driver_parser.add_argument("--write-path", action="append", default=[])
    driver_parser.add_argument("--protected-path", action="append", default=[])
    driver_parser.add_argument("--claim-id", required=True)
    driver_parser.add_argument("--work-item", required=True)
    driver_parser.add_argument("--stage", required=True, choices=("probe", "run"))
    driver_parser.add_argument("--authorization-id", required=True)
    driver_parser.add_argument("--barrier-timeout", type=float, default=30.0)
    driver_parser.add_argument("--brief")
    for action in ("probe", "run"):
        invocation_parser = subparsers.add_parser(action, help=f"{action} a verified custom CLI adapter")
        invocation_parser.add_argument("--config", required=True)
        invocation_parser.add_argument("--lane", required=True)
        invocation_parser.add_argument("--repo", required=True)
        invocation_parser.add_argument("--role", required=True, choices=tuple(ROLE_MODES))
        invocation_parser.add_argument("--sandbox", required=True, choices=("workspace-write", "read-only"))
        invocation_parser.add_argument("--report", required=True)
        invocation_parser.add_argument("--receipt", required=True)
        invocation_parser.add_argument("--write-path", action="append", default=[])
        invocation_parser.add_argument("--protected-path", action="append", default=[])
        if action == "run":
            invocation_parser.add_argument("--brief", required=True)
    args = parser.parse_args(argv)
    try:
        if args.command == "resolve":
            result = resolve_route(args.config, args.lane)
        elif args.command == "identify":
            result = identify_adapter(args)
        elif args.command == "claim":
            return claim_attempt(args)
        elif args.command == "finalize":
            return finalize_attempt(args.intent)
        elif args.command == "authorize-stage":
            return authorize_stage(args)
        elif args.command == "bind-driver":
            return bind_driver(args)
        elif args.command == "release-driver":
            return release_driver(args)
        elif args.command == "settle-stage":
            return settle_stage(args)
        elif args.command == "driver":
            if args.stage == "run" and not args.brief:
                raise RouteError("run driver requires --brief")
            if args.barrier_timeout <= 0 or args.barrier_timeout > 600:
                raise RouteError("driver barrier timeout must be between 0 and 600 seconds")
            return run_claimed_driver(args)
        else:
            raise RouteError("probe and run must use the claimed driver barrier")
    except RouteError as error:
        lane = getattr(args, "lane", "<saved-claim>")
        config = getattr(args, "config", "<saved-config>")
        print(f"Cannot continue route {lane!r}: {error}. Correction: inspect the saved claim and route configuration in {config}.", file=sys.stderr)
        return 2
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
