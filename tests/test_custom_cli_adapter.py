import hashlib
import concurrent.futures
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import uuid


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "custom-cli-adapter.py"
SANDBOX_EXEC = Path("/usr/bin/sandbox-exec")
TEST_TMPDIR = Path(__file__).resolve().parents[1] / "docs/features/.routing/task2-test-fixtures"


def sandbox_exec_available():
    if sys.platform != "darwin" or not SANDBOX_EXEC.is_file() or not TEST_TMPDIR.is_dir():
        return False
    result = subprocess.run(
        [str(SANDBOX_EXEC), "-p", "(version 1)(allow default)(deny file-write*)", "/usr/bin/true"],
        capture_output=True,
        check=False,
    )
    return result.returncode == 0


class CustomCliAdapterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        TEST_TMPDIR.mkdir(parents=True, exist_ok=True)
        TEST_TMPDIR.chmod(0o700)

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory(dir=str(TEST_TMPDIR))
        self.root = Path(self.temp_dir.name)
        self.executable = self.root / "agent runner"
        self.executable.write_text("#!/bin/sh\nexit 0\n")
        self.executable.chmod(0o755)
        self.config_path = self.root / "config.json"
        self.repo = self.root / "repo with spaces"
        self.repo.mkdir()
        self.repo_routing = self.repo / "docs/features/.routing"
        self.repo_routing.mkdir(parents=True)
        self.repo_routing.chmod(0o755)
        self.authorized_file = self.repo / "task file.txt"
        self.authorized_file.write_text("before\n")
        self.lock_dir = self.repo / ".dev-flow/locks"
        self.lock_dir.mkdir(parents=True)
        self.lock_file = self.lock_dir / "implementer.lock"
        self.lock_file.write_text("lock\n")
        self.claim_dir = self.repo / ".dev-flow/claims"
        self.claim_dir.mkdir()
        self.claim_file = self.claim_dir / "claim.json"
        self.claim_file.write_text("claim\n")
        self.state_dir = self.repo / "docs/features/.feature-states"
        self.state_dir.mkdir(parents=True)
        self.state_file = self.state_dir / "feature.state.md"
        self.state_file.write_text("state\n")
        self.git_dir = self.repo / ".git/worktrees/worker"
        self.git_dir.mkdir(parents=True)
        self.git_admin_file = self.git_dir / "admin"
        self.git_admin_file.write_text("admin\n")
        self.control_paths = (self.repo / ".dev-flow", self.state_dir, self.repo / ".git")
        self.redirect = self.repo / "authorized-link"
        self.redirect.symlink_to(self.lock_file)
        self.report_dir = Path(tempfile.mkdtemp(prefix="dev-flow-report-", dir=str(self.repo_routing)))
        self.report_dir.chmod(0o700)
        self.report = self.report_dir / "worker report.md"
        self.controller_dir = self.repo_routing / "controller"
        self.controller_dir.mkdir(mode=0o700)
        self.controller_dir.chmod(0o700)
        self.receipt = self.controller_dir / "controller receipt.json"
        self.events = self.report_dir / "recorder events.jsonl"
        self.events.write_text("")
        self.base_report = self.report
        self.base_receipt = self.receipt
        self.base_events = self.events
        self.target_repo = self.root / "separate target checkout"
        self.target_repo.mkdir()
        self.target_routing = self.target_repo / "docs/features/.routing"
        self.target_routing.mkdir(parents=True)
        self.target_routing.chmod(0o755)
        self.target_report_dir = self.target_routing / "dev-flow-report-target"
        self.target_report_dir.mkdir(mode=0o700)
        self.target_report = self.target_report_dir / "worker report.md"
        self.target_controller_dir = self.target_routing / "controller"
        self.target_controller_dir.mkdir(mode=0o700)
        self.target_controller_dir.chmod(0o700)
        self.target_receipt = self.target_controller_dir / "controller receipt.json"
        self.target_events = self.target_report_dir / "target recorder events.jsonl"
        self.target_events.write_text("")
        self.target_task = self.target_repo / "task.md"
        self.target_task.write_text("before\n")
        self.pending_claim = None
        self.executable = self.root / "fixture launcher.py"
        self.write_recorder()
        self.config_path.write_text(json.dumps({
            "cli_adapters": {"fixture": str(self.executable)},
            "cli_adapter_settings": {"fixture": {
                "environment": ["FIXTURE_EVENTS", "FIXTURE_METADATA_MODE", "FIXTURE_BASE_URL", "FIXTURE_ATTACK_PATHS", "FIXTURE_RENAME_DIRS", "FIXTURE_CREATE_PATHS", "FIXTURE_PROBE_WRITE_PATH", "FIXTURE_PROBE_REPORT_CREATE"],
                "credentials": ["FIXTURE_MODEL_TOKEN"],
                "forbidden_environment": ["FIXTURE_MODEL_OVERRIDE", "FIXTURE_SANDBOX_OVERRIDE"],
                "files": [],
            }},
        }))

    def write_recorder(self):
        recorder = '''#!/usr/bin/env python3
import argparse, json, os, subprocess, sys, time
parser = argparse.ArgumentParser()
parser.add_argument("action")
parser.add_argument("--model", required=True)
parser.add_argument("--repo", required=True)
parser.add_argument("--sandbox", required=True)
parser.add_argument("--role", required=True)
parser.add_argument("--metadata-fd", required=True, type=int)
parser.add_argument("--settings-sha256", required=True)
parser.add_argument("--brief")
parser.add_argument("--write-path", action="append", default=[])
parser.add_argument("--protected-path", action="append", default=[])
parser.add_argument("--report", required=True)
args = parser.parse_args()
event = {"action": args.action, "argv": sys.argv[1:], "cwd": os.getcwd(), "model": args.model,
         "repo": args.repo, "sandbox": args.sandbox, "role": args.role,
         "brief": args.brief, "tmpdir": os.environ.get("TMPDIR"),
         "credential_received": os.environ.get("FIXTURE_MODEL_TOKEN") == "fixture-secret"}
event["attempts"] = []
for path in json.loads(os.environ.get("FIXTURE_ATTACK_PATHS", "[]")) if args.action == "run" else []:
    for operation in ("write", "unlink", "rename", "replace"):
        try:
            if operation == "write":
                with open(path, "w") as target:
                    target.write("tampered\\n")
            elif operation == "unlink":
                os.unlink(path)
            elif operation == "rename":
                os.rename(path, path + ".moved")
            else:
                payload = os.path.join(os.path.dirname(args.report), "replacement payload")
                with open(payload, "w") as target:
                    target.write("replacement\\n")
                os.replace(payload, path)
            event["attempts"].append({"path": path, "operation": operation, "denied": False})
        except OSError:
            event["attempts"].append({"path": path, "operation": operation, "denied": True})
for path in json.loads(os.environ.get("FIXTURE_RENAME_DIRS", "[]")) if args.action == "run" else []:
    try:
        os.rename(path, path + ".moved")
        event["attempts"].append({"path": path, "operation": "rename-parent", "denied": False})
    except OSError:
        event["attempts"].append({"path": path, "operation": "rename-parent", "denied": True})
for path in json.loads(os.environ.get("FIXTURE_CREATE_PATHS", "[]")) if args.action == "run" else []:
    try:
        with open(path, "w") as target:
            target.write("unassigned\\n")
        event["attempts"].append({"path": path, "operation": "create", "denied": False})
    except OSError:
        event["attempts"].append({"path": path, "operation": "create", "denied": True})
if args.action == "probe" and os.environ.get("FIXTURE_PROBE_REPORT_CREATE"):
    side_file = os.path.join(os.path.dirname(args.report), "probe-side.txt")
    try:
        with open(side_file, "w") as stream:
            stream.write("probe side effect")
        event["report_creation_denied"] = False
    except PermissionError:
        event["report_creation_denied"] = True
if args.role == "reviewer" or args.action == "probe":
    print("fixture event: " + json.dumps(event), file=sys.stderr)
else:
    with open(os.environ["FIXTURE_EVENTS"], "a") as stream:
        stream.write(json.dumps(event) + "\\n")
mode = os.environ.get("FIXTURE_METADATA_MODE", "matching")
if mode != "missing":
    mismatch = mode == "mismatch" or (mode == "mismatch-on-run" and args.action == "run")
    observed = "wrong/model" if mismatch else args.model
    metadata = {"schema_version": 1, "observed_model_id": observed,
                "role": args.role, "permission_mode": "read-only" if mode == "denied" else args.sandbox,
                "settings_sha256": args.settings_sha256, "backend_id": "fixture-recorder"}
    if mode != "missing-source":
        metadata["model_id_source"] = "invalid-source" if mode == "invalid-source" else "backend-event"
    if mode == "object-source":
        metadata["model_id_source"] = {"source": "backend-event"}
    if mode == "array-source":
        metadata["model_id_source"] = ["backend-event"]
    if mode == "boolean-version":
        metadata["schema_version"] = True
    if mode == "fractional-version":
        metadata["schema_version"] = 1.0
    if mode == "malformed" or (mode == "malformed-on-run" and args.action == "run"):
        with os.fdopen(args.metadata_fd, "w") as stream:
            stream.write("{")
    else:
        with os.fdopen(args.metadata_fd, "w") as stream:
            json.dump(metadata, stream)
if args.action == "run":
    if args.write_path:
        with open(args.write_path[0], "wb") as stream:
            stream.write(b"after\\r\\n" if mode == "crlf-run" else b"after\\n")
    if args.role == "reviewer":
        try:
            with open(args.report, "w") as stream:
                stream.write("unexpected worker file\\n")
        except PermissionError:
            pass
    elif mode != "missing-report":
        with open(args.report, "w") as stream:
            stream.write("fixture report\\n")
    print("fixture role output")
if args.action == "probe" and os.environ.get("FIXTURE_PROBE_WRITE_PATH"):
    with open(os.environ["FIXTURE_PROBE_WRITE_PATH"], "w") as stream:
        stream.write("probe changed task\\n")
print("fixture warning", file=sys.stderr)
if args.action == "run" and mode in {"timeout-on-run", "lingering-child-on-run"}:
    sys.stdout.flush()
    sys.stderr.flush()
    if mode == "timeout-on-run":
        time.sleep(30)
    else:
        subprocess.Popen(
            [sys.executable, "-c", "import time; time.sleep(30)"],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
if mode == "nonzero":
    raise SystemExit(7)
'''
        compile(recorder, str(self.executable), "exec")
        self.executable.write_text(recorder)
        self.executable.chmod(0o755)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_finalization_without_run_cannot_publish(self):
        fixture = self.root / "finalization checkout"
        fixture.mkdir()

        def git(*arguments, env=None):
            result = subprocess.run(
                ["git", "-C", str(fixture), *arguments],
                text=True, capture_output=True, check=False, env=env,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout.strip()

        git("init", "-q")
        git("config", "user.name", "Task Fixture")
        git("config", "user.email", "task-fixture@example.invalid")
        task = fixture / "task.md"
        unrelated = fixture / "unrelated.md"
        state = fixture / "docs/features/.feature-states/task.state.md"
        state.parent.mkdir(parents=True)
        task.write_text("baseline\n")
        unrelated.write_text("baseline unrelated\n")
        state.write_text("before checkpoint\n")
        git("add", "task.md", "unrelated.md", "docs/features/.feature-states/task.state.md")
        git("commit", "-q", "-m", "fixture baseline")
        baseline_commit = git("rev-parse", "HEAD")
        unrelated.write_text("pre-existing staged change\n")
        git("add", "unrelated.md")

        claim = subprocess.run(
            [sys.executable, str(SCRIPT), "claim", "--config", str(self.config_path), "--repo", str(fixture), "--role", "implementer",
             "--work-item", "task-1", "--lane", "cli:fixture/model-v1", "--write-path", str(task)],
            text=True, capture_output=True, check=False,
        )
        self.assertEqual(claim.returncode, 0, claim.stderr)
        claim_record = json.loads(claim.stdout)
        self.assertEqual(claim_record["route"], "cli:fixture/model-v1")

        task.write_text("accepted task result\n")
        routing = fixture / "docs/features/.routing"
        attempt_dir = Path(claim_record["attempt_dir"])
        report = attempt_dir / "worker-report.md"
        report.write_text("accepted report\n")
        report_digest = hashlib.sha256(report.read_bytes()).hexdigest()
        intent = attempt_dir / "finalization-intent.json"
        intent.write_text(json.dumps({
            "schema_version": 1,
            "outcome": "accepted",
            "claim_id": claim_record["claim_id"],
            "role": "implementer",
            "work_item": "task-1",
            "route": "cli:fixture/model-v1",
            "repo": str(fixture.resolve()),
            "expected_head": baseline_commit,
            "report": {"source": str(report), "sha256": report_digest},
            "checkpoint": {
                "path": str(state),
                "expected_sha256": hashlib.sha256(b"before checkpoint\n").hexdigest(),
                "content": "accepted task-1 checkpoint\n",
            },
            "commit": {
                "enabled": True,
                "message": "feat: accept fixture task",
                "paths": [{"path": "task.md", "sha256": hashlib.sha256(b"accepted task result\n").hexdigest()}],
            },
        }))

        result = subprocess.run(
            [sys.executable, str(SCRIPT), "finalize", "--intent", str(intent)],
            text=True, capture_output=True, check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("completed run", result.stderr)
        self.assertEqual(git("rev-parse", "HEAD"), baseline_commit)
        self.assertEqual(git("diff", "--cached", "--", "unrelated.md").count("pre-existing staged change"), 1)
        self.assertEqual(state.read_text(), "before checkpoint\n")
        self.assertFalse((attempt_dir / "accepted-report.md").exists())
        self.assertEqual(json.loads((routing / "claims/implementer/task-1.json").read_text())["state"], "active")

        def authorize(work_item):
            return subprocess.run(
                [sys.executable, str(SCRIPT), "authorize-stage", "--repo", str(fixture), "--role", "implementer",
                 "--work-item", work_item, "--claim-id", claim_record["claim_id"], "--stage", "probe"],
                text=True, capture_output=True, check=False,
            )

        invalid = authorize("../task-1")
        self.assertNotEqual(invalid.returncode, 0)
        self.assertIn("work item", invalid.stderr)
        git("commit", "-q", "--allow-empty", "--only", "-m", "move fixture head")
        moved = authorize("task-1")
        self.assertNotEqual(moved.returncode, 0)
        self.assertIn("head changed", moved.stderr)

    def test_real_run_change_can_be_accepted_and_committed_with_clean_index(self):
        self.assert_sandbox_available()
        fixture = self.root / "bound attempt checkout"
        fixture.mkdir()

        def git(*arguments):
            result = subprocess.run(
                ["git", "-C", str(fixture), *arguments], text=True,
                capture_output=True, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout.strip()

        git("init", "-q")
        git("config", "user.name", "Task Fixture")
        git("config", "user.email", "task-fixture@example.invalid")
        task = fixture / "task.md"
        unrelated = fixture / "unrelated.md"
        state = fixture / "docs/features/.feature-states/task.state.md"
        state.parent.mkdir(parents=True)
        task.write_text("before\n")
        (fixture / ".gitattributes").write_text("task.md text eol=lf\n")
        git("config", "core.filemode", "true")
        unrelated.write_text("unrelated baseline\n")
        state.write_text("before checkpoint\n")
        git("add", ".gitattributes", "task.md", "unrelated.md", "docs/features/.feature-states/task.state.md")
        git("commit", "-q", "-m", "fixture baseline")
        baseline_head = git("rev-parse", "HEAD")
        unrelated.write_text("user staged bytes\n")
        git("add", "unrelated.md")

        (self.root / "brief with spaces.md").write_text("Implement the fixture task.\n")
        environment = {"FIXTURE_METADATA_MODE": "crlf-run"}
        probe = self.invoke("probe", repo=fixture, write_paths=(task,), extra_env=environment)
        self.assertEqual(probe.returncode, 0, probe.stderr)
        claim_path = Path(self.pending_claim["claim_path"])
        run = self.invoke("run", repo=fixture, write_paths=(task,), extra_env=environment)
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertEqual(task.read_bytes(), b"after\r\n")
        claim = json.loads(claim_path.read_text())
        self.assertEqual(claim["stages"]["probe"]["status"], "complete")
        self.assertEqual(claim["stages"]["run"]["status"], "complete")
        self.assert_consumed_authorization_blocks(run, claim_path, "run")

        report = Path(self.report)
        intent = Path(claim["attempt_dir"]) / "finalization-intent.json"
        accepted_intent = {
            "schema_version": 1,
            "outcome": "accepted",
            "claim_id": claim["claim_id"],
            "role": "implementer",
            "work_item": claim["work_item"],
            "route": claim["route"],
            "repo": str(fixture.resolve()),
            "expected_head": baseline_head,
            "report": {"source": str(report), "sha256": hashlib.sha256(report.read_bytes()).hexdigest()},
            "checkpoint": {
                "path": str(state),
                "expected_sha256": hashlib.sha256(b"before checkpoint\n").hexdigest(),
                "content": "accepted task checkpoint\n",
            },
            "commit": {"enabled": True, "message": "feat: accept fixture task", "paths": [
                {"path": "task.md", "sha256": hashlib.sha256(task.read_bytes()).hexdigest()},
            ]},
        }
        arguments = [sys.executable, str(SCRIPT), "finalize", "--intent", str(intent)]

        def finalize():
            return subprocess.run(arguments, text=True, capture_output=True, check=False)

        stale_report = intent.parent / "stale.md"
        stale_report.write_text("unrelated result\n")
        intent.write_text(json.dumps({
            **accepted_intent,
            "report": {"source": str(stale_report), "sha256": hashlib.sha256(stale_report.read_bytes()).hexdigest()},
        }))
        stale = finalize()
        self.assertNotEqual(stale.returncode, 0)
        self.assertIn("matching completed run", stale.stderr)
        self.assertFalse((intent.parent / "accepted-report.md").exists())
        intent.write_text(json.dumps(accepted_intent))

        state.write_text("concurrent checkpoint change\n")
        blocked = finalize()
        self.assertNotEqual(blocked.returncode, 0)
        self.assertIn("checkpoint changed", blocked.stderr)
        self.assertEqual(git("rev-parse", "HEAD"), baseline_head)
        self.assertFalse((intent.parent / "accepted-report.md").exists())
        state.write_text("before checkpoint\n")

        task_mode = task.stat().st_mode & 0o777
        content_status = git("status", "--porcelain=v1", "--", "task.md")
        task.chmod(task_mode | 0o100)
        try:
            self.assertEqual(git("status", "--porcelain=v1", "--", "task.md"), content_status)
            changed_mode = finalize()
            self.assertEqual(changed_mode.returncode, 2, changed_mode.stderr)
            self.assertIn("reviewed write-scope evidence changed", changed_mode.stderr)
            self.assertEqual(git("rev-parse", "HEAD"), baseline_head)
            self.assertEqual(state.read_text(), "before checkpoint\n")
        finally:
            task.chmod(task_mode)

        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            first, second = list(pool.map(lambda _: finalize(), range(2)))
        for finalized in (first, second):
            self.assertEqual(finalized.returncode, 0, finalized.stderr)
        self.assertEqual(sorted(json.loads(result.stdout)["recovered"] for result in (first, second)), [False, True])
        committed_head = git("rev-parse", "HEAD")
        self.assertEqual(git("rev-list", "--count", f"{baseline_head}..HEAD"), "1")
        self.assertEqual(git("diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"), "task.md")
        self.assertEqual(git("show", "HEAD:task.md"), "after")
        committed = subprocess.check_output(["git", "-C", str(fixture), "show", "HEAD:task.md"])
        self.assertEqual(committed, b"after\n")
        self.assertEqual(git("status", "--porcelain=v1", "--", "task.md"), "")
        self.assertEqual(git("diff", "--cached", "--", "unrelated.md").count("user staged bytes"), 1)
        self.assertEqual(state.read_text(), "accepted task checkpoint\n")
        self.assertEqual((intent.parent / "accepted-report.md").read_text(), report.read_text())

        task_blob = git("rev-parse", "HEAD:task.md")
        task_entries = {"task.md": {"mode": "100644", "oid": task_blob}}
        self.assertEqual(json.loads(claim_path.read_text())["pending_commit_entries"], task_entries)
        pending = {
            **claim,
            "state": "pending-finalization",
            "pending_commit_entries": task_entries,
            "pending_finalization": hashlib.sha256(
                json.dumps(accepted_intent, sort_keys=True, separators=(",", ":")).encode()
            ).hexdigest(),
        }
        # Seed the record written before any effects, then vary which effects survived.
        for checkpoint_written in (False, True):
            with self.subTest(checkpoint_written=checkpoint_written):
                claim_path.write_text(json.dumps(pending))
                if not checkpoint_written:
                    state.write_text("before checkpoint\n")
                    (intent.parent / "accepted-report.md").rename(intent.parent / "prior-fixture-report.md")
                resumed = finalize()
                self.assertEqual(resumed.returncode, 0, resumed.stderr)
                self.assertEqual(git("rev-parse", "HEAD"), committed_head)
                self.assertEqual(state.read_text(), "accepted task checkpoint\n")
                self.assertEqual((intent.parent / "accepted-report.md").read_bytes(), report.read_bytes())
                terminal = json.loads(claim_path.read_text())
                self.assertEqual(terminal["state"], "finalized")
                self.assertEqual(terminal["outcome"], "accepted")
                self.assertEqual(terminal["commit_id"], committed_head)
                self.assertEqual(terminal["pending_commit_entries"], task_entries)
                self.assertEqual(terminal["checkpoint_sha256"], hashlib.sha256(state.read_bytes()).hexdigest())
                self.assertEqual(terminal["finalization_sha256"], pending["pending_finalization"])

        tester_probe = self.invoke("probe", repo=fixture, role="tester", write_paths=())
        self.assertEqual(tester_probe.returncode, 0, tester_probe.stderr)
        tester_claim_path = Path(self.pending_claim["claim_path"])
        tester_run = self.invoke("run", repo=fixture, role="tester", write_paths=())
        self.assertEqual(tester_run.returncode, 0, tester_run.stderr)
        tester_claim = json.loads(tester_claim_path.read_text())
        self.assertNotEqual(tester_claim["claim_id"], claim["claim_id"])
        self.assertEqual(tester_claim["route"], claim["route"])
        receipt = json.loads(self.receipt.read_text())
        self.assertEqual(receipt["observed_model_id"], "model/v1")
        self.assertEqual(receipt["backend_id"], "fixture-recorder")
        self.assertEqual(receipt["permission_mode"], "workspace-write")
        tester_intent = Path(tester_claim["attempt_dir"]) / "finalization-intent.json"
        tester_intent.write_text(json.dumps({
            **accepted_intent,
            "role": "tester",
            "claim_id": tester_claim["claim_id"],
            "work_item": tester_claim["work_item"],
            "expected_head": committed_head,
            "report": {"source": str(self.report), "sha256": hashlib.sha256(self.report.read_bytes()).hexdigest()},
            "checkpoint": {
                "path": str(state),
                "expected_sha256": hashlib.sha256(state.read_bytes()).hexdigest(),
                "content": "accepted tester checkpoint\n",
            },
            "commit": {"enabled": False, "message": "", "paths": []},
        }))
        tested = subprocess.run(
            [sys.executable, str(SCRIPT), "finalize", "--intent", str(tester_intent)],
            text=True, capture_output=True, check=False,
        )
        self.assertEqual(tested.returncode, 0, tested.stderr)
        self.assertEqual((tester_intent.parent / "accepted-report.md").read_bytes(), self.report.read_bytes())
        self.assertEqual(state.read_text(), "accepted tester checkpoint\n")
        self.assertEqual(git("rev-parse", "HEAD"), committed_head)

        # Construct a different candidate commit in this disposable repository.
        # Ignore worktree mode in porcelain so recovery has to verify the tree.
        task.chmod(task_mode | 0o100)
        git("commit", "--amend", "--only", "-qm", "fixture candidate mode", "--", "task.md")
        task.chmod(task_mode)
        git("config", "core.filemode", "false")
        self.assertTrue(git("ls-tree", "HEAD", "--", "task.md").startswith("100755 "))
        self.assertEqual(git("status", "--porcelain=v1", "--", "task.md"), "")
        self.assertEqual(git("rev-parse", "HEAD:task.md"), task_blob)
        candidate_head = git("rev-parse", "HEAD")
        claim_path.write_text(json.dumps(pending))
        state.write_text("before checkpoint\n")
        wrong_mode = finalize()
        self.assertEqual(wrong_mode.returncode, 2, wrong_mode.stderr)
        self.assertIn("existing commit tree entry does not match", wrong_mode.stderr)
        self.assertEqual(git("rev-parse", "HEAD"), candidate_head)
        self.assertEqual(state.read_text(), "before checkpoint\n")

    def test_report_only_terminal_stops_survive_resume(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("implement fixture task")
        for outcome in ("worker_failed", "needs_context", "rejected"):
            with self.subTest(outcome=outcome):
                fixture = self.root / f"terminal {outcome} checkout"
                fixture.mkdir()

                def git(*arguments):
                    result = subprocess.run(
                        ["git", "-C", str(fixture), *arguments],
                        text=True, capture_output=True, check=False,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    return result.stdout.strip()

                git("init", "-q")
                git("config", "user.name", "Task Fixture")
                git("config", "user.email", "task-fixture@example.invalid")
                task = fixture / "task.md"
                task.write_text("unchanged\n")
                state = fixture / "docs/features/.feature-states/task.state.md"
                state.parent.mkdir(parents=True)
                state.write_text("before\n")
                git("add", "task.md", "docs/features/.feature-states/task.state.md")
                git("commit", "-q", "-m", "fixture baseline")
                head = git("rev-parse", "HEAD")
                probe = self.invoke("probe", repo=fixture, write_paths=(task,))
                self.assertEqual(probe.returncode, 0, probe.stderr)
                claim_path = Path(self.pending_claim["claim_path"])
                run = self.invoke("run", repo=fixture, write_paths=(task,))
                self.assertEqual(run.returncode, 0, run.stderr)
                claim = json.loads(claim_path.read_text())
                attempt = Path(claim["attempt_dir"])
                report = self.report
                state_content = f"{outcome} terminal\n"
                intent = attempt / "finalization-intent.json"
                disposition = {
                    "schema_version": 1,
                    "outcome": outcome,
                    "claim_id": claim["claim_id"],
                    "role": "implementer",
                    "work_item": claim["work_item"],
                    "route": claim["route"],
                    "repo": str(fixture.resolve()),
                    "expected_head": head,
                    "report": {"source": str(report), "sha256": hashlib.sha256(report.read_bytes()).hexdigest()},
                    "checkpoint": {
                        "path": str(state),
                        "expected_sha256": hashlib.sha256(b"before\n").hexdigest(),
                        "content": state_content,
                    },
                    "commit": {"enabled": False, "paths": [], "message": ""},
                }
                arguments = [sys.executable, str(SCRIPT), "finalize", "--intent", str(intent)]
                intent.write_text(json.dumps({**disposition, "outcome": "failed"}))
                disguised = subprocess.run(arguments, text=True, capture_output=True, check=False)
                self.assertNotEqual(disguised.returncode, 0)
                self.assertIn("worker outcome", disguised.stderr)
                self.assertEqual(state.read_text(), "before\n")
                intent.write_text(json.dumps(disposition))
                first = subprocess.run(arguments, text=True, capture_output=True, check=False)
                second = subprocess.run(arguments, text=True, capture_output=True, check=False)
                self.assertEqual(first.returncode, 0, first.stderr)
                self.assertEqual(second.returncode, 0, second.stderr)
                self.assertEqual(json.loads(first.stdout)["status"], "stopped")
                self.assertTrue(json.loads(second.stdout)["recovered"])
                self.assertFalse((attempt / "accepted-report.md").exists())
                self.assertEqual((attempt / "terminal-report.md").read_bytes(), report.read_bytes())
                self.assertEqual(state.read_text(), state_content)
                self.assertEqual(git("rev-parse", "HEAD"), head)
                retry = subprocess.run(
                    [sys.executable, str(SCRIPT), "claim", "--config", str(self.config_path),
                     "--repo", str(fixture), "--role", "implementer", "--work-item", claim["work_item"],
                     "--lane", claim["route"], "--write-path", str(task), "--retry-claim", claim["claim_id"]],
                    text=True, capture_output=True, check=False,
                )
                self.assertNotEqual(retry.returncode, 0)
                self.assertIn("terminal disposition", retry.stderr)

    def test_finalization_refuses_to_commit_preexisting_change_on_task_path(self):
        self.assert_sandbox_available()
        fixture = self.root / "overlap checkout"
        fixture.mkdir()

        def git(*arguments):
            result = subprocess.run(
                ["git", "-C", str(fixture), *arguments], text=True,
                capture_output=True, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout.strip()

        git("init", "-q")
        git("config", "user.name", "Task Fixture")
        git("config", "user.email", "task-fixture@example.invalid")
        task = fixture / "task.md"
        state = fixture / "docs/features/.feature-states/task.state.md"
        state.parent.mkdir(parents=True)
        task.write_text("base\n")
        state.write_text("before\n")
        git("add", "task.md", "docs/features/.feature-states/task.state.md")
        git("commit", "-q", "-m", "fixture baseline")
        head = git("rev-parse", "HEAD")
        task.write_text("pre-existing user edit\n")
        git("add", "task.md")
        (self.root / "brief with spaces.md").write_text("implement the fixture")
        probe = self.invoke("probe", repo=fixture, write_paths=(task,))
        self.assertEqual(probe.returncode, 0, probe.stderr)
        claim_path = Path(self.pending_claim["claim_path"])
        run = self.invoke("run", repo=fixture, write_paths=(task,))
        self.assertEqual(run.returncode, 0, run.stderr)
        claim = json.loads(claim_path.read_text())
        attempt = Path(claim["attempt_dir"])
        report = self.report
        intent = attempt / "finalization-intent.json"
        intent.write_text(json.dumps({
            "schema_version": 1, "outcome": "accepted", "claim_id": claim["claim_id"],
            "role": "implementer", "work_item": claim["work_item"], "route": claim["route"],
            "repo": str(fixture.resolve()), "expected_head": head,
            "report": {"source": str(report), "sha256": hashlib.sha256(report.read_bytes()).hexdigest()},
            "checkpoint": {
                "path": str(state), "expected_sha256": hashlib.sha256(b"before\n").hexdigest(),
                "content": "should remain untouched\n",
            },
            "commit": {"enabled": True, "message": "feat: mixed task", "paths": [
                {"path": "task.md", "sha256": hashlib.sha256(task.read_bytes()).hexdigest()},
            ]},
        }))

        result = subprocess.run(
            [sys.executable, str(SCRIPT), "finalize", "--intent", str(intent)],
            text=True, capture_output=True, check=False,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("reconcile", result.stderr.lower())
        self.assertEqual(git("rev-parse", "HEAD"), head)
        self.assertEqual(git("diff", "--cached", "--", "task.md").count("pre-existing user edit"), 1)
        self.assertEqual(state.read_text(), "before\n")
        self.assertFalse((attempt / "accepted-report.md").exists())

    def resolve(self, lane, config=None, extra_env=None):
        if config is not None:
            self.config_path.write_text(json.dumps(config))
        return subprocess.run(
            [sys.executable, str(SCRIPT), "resolve", "--config", str(self.config_path), "--lane", lane],
            text=True,
            capture_output=True,
            check=False,
            env={**os.environ, **(extra_env or {})},
        )

    def identify(self, lane, expected_identity=None, extra_env=None):
        arguments = [sys.executable, str(SCRIPT), "identify", "--config", str(self.config_path), "--lane", lane]
        if expected_identity is not None:
            arguments.extend(("--expected-identity", expected_identity))
        return subprocess.run(arguments, text=True, capture_output=True, check=False,
                              env={**os.environ, **(extra_env or {})})

    def invoke(self, action, *, lane="cli:fixture/model/v1", role="implementer", sandbox="workspace-write",
               extra_env=None, receipt=None, write_paths=None, repo=None, report=None, driver_entry=None,
               expected_identity=None):
        environment = {**os.environ, "FIXTURE_MODEL_TOKEN": "fixture-secret", **(extra_env or {})}
        selected_repo = Path(repo or self.repo).resolve()
        selected_paths = tuple(Path(path).absolute() for path in (write_paths if write_paths is not None else (self.authorized_file,) if role != "reviewer" else ()))
        claim = self.pending_claim if action == "run" else None
        if (not claim or claim["repo"] != str(selected_repo) or claim["role"] != role
                or claim["write_paths"] != [str(path) for path in selected_paths]):
            work_item = f"fixture-{uuid.uuid4().hex}"
            claim_arguments = [
                sys.executable, str(SCRIPT), "claim", "--config", str(self.config_path),
                "--repo", str(selected_repo), "--role", role, "--work-item", work_item, "--lane", lane,
            ]
            for path in selected_paths:
                claim_arguments.extend(("--write-path", str(path)))
            if role == "reviewer":
                if expected_identity is None:
                    identity = self.identify(lane, extra_env=environment)
                    if identity.returncode != 0:
                        return identity
                    expected_identity = json.loads(identity.stdout)["identity_sha256"]
                claim_arguments.extend(("--expected-identity", expected_identity))
            claim_result = subprocess.run(claim_arguments, text=True, capture_output=True, check=False, env=environment)
            if claim_result.returncode != 0:
                return claim_result
            claim = json.loads(claim_result.stdout)
            claim["repo"] = str(selected_repo)
            claim["role"] = role
            claim["write_paths"] = [str(path) for path in selected_paths]
        if action == "probe":
            self.pending_claim = claim
        attempt_dir = Path(claim["attempt_dir"])
        report_dir = attempt_dir / "dev-flow-report-worker"
        report_dir.mkdir(mode=0o700, exist_ok=True)
        report_dir.chmod(0o700)
        selected_report = Path(report).resolve() if report else report_dir / "worker report.md"
        selected_receipt = Path(receipt).resolve() if receipt else attempt_dir / "controller receipt.json"
        self.report = selected_report
        self.receipt = selected_receipt
        self.events = report_dir / "recorder events.jsonl"
        if not self.events.exists():
            self.events.write_text("")
        if role != "reviewer":
            environment.setdefault("FIXTURE_EVENTS", str(self.events))

        auth_result = subprocess.run(
            [sys.executable, str(SCRIPT), "authorize-stage", "--repo", str(selected_repo), "--role", role,
             "--work-item", claim["work_item"], "--claim-id", claim["claim_id"], "--stage", action],
            text=True, capture_output=True, check=False,
        )
        if auth_result.returncode != 0:
            return auth_result
        authorization = json.loads(auth_result.stdout)["authorization_id"]
        driver_arguments = [
            sys.executable, str(driver_entry or SCRIPT), "driver", "--config", str(self.config_path), "--lane", lane,
            "--repo", str(selected_repo), "--role", role, "--sandbox", sandbox,
            "--report", str(selected_report), "--receipt", str(selected_receipt),
            "--claim-id", claim["claim_id"], "--work-item", claim["work_item"],
            "--stage", action, "--authorization-id", authorization,
        ]
        for path in selected_paths:
            driver_arguments.extend(("--write-path", str(path)))
        for path in self.control_paths:
            driver_arguments.extend(("--protected-path", str(path)))
        if action == "run":
            driver_arguments.extend(("--brief", str(self.root / "brief with spaces.md")))
        driver = subprocess.Popen(
            driver_arguments, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            env=environment,
        )
        ready_line = driver.stderr.readline()
        if not ready_line:
            stdout, stderr = driver.communicate()
            return subprocess.CompletedProcess(driver_arguments, driver.returncode, stdout, stderr)
        try:
            ready = json.loads(ready_line)
        except json.JSONDecodeError:
            stdout, stderr = driver.communicate()
            return subprocess.CompletedProcess(driver_arguments, driver.returncode, stdout, ready_line + stderr)
        control_arguments = [sys.executable, str(SCRIPT), "bind-driver", "--repo", str(selected_repo), "--role", role,
                             "--work-item", claim["work_item"], "--claim-id", claim["claim_id"], "--stage", action,
                             "--authorization-id", authorization, "--handle", str(ready["driver_handle"])]
        bound = subprocess.run(control_arguments, text=True, capture_output=True, check=False)
        if bound.returncode == 0:
            control_arguments[2] = "release-driver"
            released = subprocess.run(control_arguments, text=True, capture_output=True, check=False)
            if released.returncode != 0:
                driver.terminate()
                stdout, stderr = driver.communicate()
                return subprocess.CompletedProcess(driver_arguments, released.returncode, stdout, stderr + released.stderr)
        else:
            driver.terminate()
            stdout, stderr = driver.communicate()
            return subprocess.CompletedProcess(driver_arguments, bound.returncode, stdout, stderr + bound.stderr)
        stdout, stderr = driver.communicate(timeout=30)
        if action == "probe" and role != "reviewer":
            with self.events.open("a") as log:
                for line in stderr.splitlines():
                    if line.startswith("fixture event: "):
                        log.write(line.removeprefix("fixture event: ") + "\n")
        if action == "run":
            self.pending_claim = None
        return subprocess.CompletedProcess(driver_arguments, driver.returncode, stdout, stderr)

    def test_receipt_and_report_follow_target_checkout_not_helper_install(self):
        self.assert_sandbox_available()
        result = self.invoke(
            "probe", repo=self.target_repo, write_paths=(self.target_task,),
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.receipt.is_file())
        self.assertTrue(str(self.receipt).startswith(str(self.target_routing)))
        self.assertEqual(self.base_events.read_text(), "")
        event = json.loads(self.events.read_text().splitlines()[-1])
        self.assertTrue(event["tmpdir"].startswith(str(self.target_routing)))

    def test_target_receipt_cannot_be_redirected_to_plugin_checkout(self):
        result = self.invoke(
            "probe", repo=self.target_repo, receipt=self.base_receipt,
            write_paths=(self.target_task,),
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("attempt", result.stderr.lower())
        self.assertEqual(self.events.read_text(), "")

    def test_target_report_cannot_be_redirected_to_plugin_checkout(self):
        result = self.invoke(
            "probe", repo=self.target_repo, report=self.base_report,
            write_paths=(self.target_task,),
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("attempt", result.stderr.lower())
        self.assertEqual(self.events.read_text(), "")

    def test_symlinked_target_routing_root_is_rejected(self):
        self.target_events.unlink()
        self.target_report_dir.rmdir()
        self.target_controller_dir.rmdir()
        self.target_routing.rmdir()
        self.target_routing.symlink_to(self.root, target_is_directory=True)

        result = self.invoke(
            "probe", repo=self.target_repo, report=self.target_report, receipt=self.target_receipt,
            write_paths=(self.target_task,),
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlink", result.stderr.lower())
        self.assertEqual(self.events.read_text(), "")

    def test_new_task_file_is_writable_and_unassigned_sibling_is_not(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("implement fixture task\n")
        new_task = self.repo / "new task.md"
        sibling = self.repo / "unassigned sibling.md"
        environment = {"FIXTURE_CREATE_PATHS": json.dumps([str(sibling)])}
        probe = self.invoke("probe", write_paths=(new_task,), extra_env=environment)
        self.assertEqual(probe.returncode, 0, probe.stderr)
        result = self.invoke("run", write_paths=(new_task,), extra_env=environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(new_task.read_text(), "after\n")
        self.assertFalse(sibling.exists())
        event = [json.loads(line) for line in self.events.read_text().splitlines()][-1]
        self.assertTrue(event["tmpdir"].startswith(str(self.repo / "docs/features/.routing")))
        sibling_attempt = next(item for item in event["attempts"] if item["path"] == str(sibling))
        self.assertTrue(sibling_attempt["denied"])

    def assert_sandbox_available(self):
        if not sandbox_exec_available():
            self.skipTest("sandbox-exec cannot verify enforcement in this host context")

    def test_resolves_exact_model_suffix_and_canonical_executable(self):
        result = self.resolve(
            "cli:local/gateway/model/v2.1",
            {"cli_adapters": {"local": str(self.executable)}},
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(result.stdout),
            {
                "status": "custom-adapter",
                "adapter": "local",
                "executable": str(self.executable.resolve()),
                "sha256": hashlib.sha256(self.executable.read_bytes()).hexdigest(),
                "model": "gateway/model/v2.1",
                "route": "cli:local/gateway/model/v2.1",
            },
        )

    def test_probe_cannot_launch_without_the_claimed_driver_barrier(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "probe", "--config", str(self.config_path),
             "--lane", "cli:fixture/model/v1", "--repo", str(self.repo),
             "--role", "implementer", "--sandbox", "workspace-write", "--report", str(self.report),
             "--receipt", str(self.receipt), "--write-path", str(self.authorized_file)],
            text=True, capture_output=True, check=False,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("driver barrier", result.stderr.lower())
        self.assertNotIn("fixture event: ", result.stderr)
        self.assertFalse(self.receipt.exists())

        claim_result = subprocess.run(
            [sys.executable, str(SCRIPT), "claim", "--config", str(self.config_path), "--repo", str(self.repo),
             "--role", "implementer", "--work-item", "unbound-driver", "--lane", "cli:fixture/model/v1",
             "--write-path", str(self.authorized_file)],
            text=True, capture_output=True, check=False,
        )
        self.assertEqual(claim_result.returncode, 0, claim_result.stderr)
        claim = json.loads(claim_result.stdout)
        auth_result = subprocess.run(
            [sys.executable, str(SCRIPT), "authorize-stage", "--repo", str(self.repo), "--role", "implementer",
             "--work-item", "unbound-driver", "--claim-id", claim["claim_id"], "--stage", "probe"],
            text=True, capture_output=True, check=False,
        )
        self.assertEqual(auth_result.returncode, 0, auth_result.stderr)
        authorization = json.loads(auth_result.stdout)["authorization_id"]
        attempt_dir = Path(claim["attempt_dir"])
        report_dir = attempt_dir / "dev-flow-report-unbound"
        report_dir.mkdir(mode=0o700)
        driver = subprocess.run(
            [sys.executable, str(SCRIPT), "driver", "--config", str(self.config_path), "--lane", "cli:fixture/model/v1",
             "--repo", str(self.repo), "--role", "implementer", "--sandbox", "workspace-write",
             "--report", str(report_dir / "report.md"), "--receipt", str(attempt_dir / "receipt.json"),
             "--write-path", str(self.authorized_file),
             "--claim-id", claim["claim_id"], "--work-item", "unbound-driver", "--stage", "probe",
             "--authorization-id", authorization, "--barrier-timeout", "0.1"],
            text=True, capture_output=True, check=False,
        )
        self.assertNotEqual(driver.returncode, 0)
        self.assertIn("barrier timed out", driver.stderr.lower())
        self.assertNotIn("fixture event: ", driver.stderr)
        self.assertFalse((attempt_dir / "receipt.json").exists())
        probe_stage = json.loads(Path(claim["claim_path"]).read_text())["stages"]["probe"]
        self.assertEqual(probe_stage["status"], "ready")
        self.assertIsNone(probe_stage["driver_handle"])
        self.assertNotIn("adapter_process_group", probe_stage)

    def test_probe_that_changes_task_scope_invalidates_the_attempt(self):
        self.assert_sandbox_available()
        result = self.invoke("probe", extra_env={"FIXTURE_PROBE_WRITE_PATH": str(self.authorized_file)})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("changed the captured task write scope", result.stderr.lower())
        self.assertEqual(self.authorized_file.read_text(), "probe changed task\n")
        claim = json.loads(Path(self.pending_claim["claim_path"]).read_text())
        self.assertEqual(claim["stages"]["probe"]["status"], "invalidated")
        run_authorization = subprocess.run(
            [sys.executable, str(SCRIPT), "authorize-stage", "--repo", str(self.repo), "--role", "implementer",
             "--work-item", claim["work_item"], "--claim-id", claim["claim_id"], "--stage", "run"],
            text=True, capture_output=True, check=False,
        )
        self.assertNotEqual(run_authorization.returncode, 0)
        self.assertIn("completed, unchanged probe", run_authorization.stderr.lower())

    def test_probe_cannot_create_files_in_formal_report_directory(self):
        self.assert_sandbox_available()
        environment = {"FIXTURE_PROBE_REPORT_CREATE": "1"}
        probe = self.invoke("probe", extra_env=environment)
        self.assertEqual(probe.returncode, 0, probe.stderr)
        self.assertTrue(json.loads(self.events.read_text())["report_creation_denied"])
        side_file = self.report.parent / "probe-side.txt"
        self.assertFalse(side_file.exists())
        (self.root / "brief with spaces.md").write_text("implement the fixture")
        run = self.invoke("run", extra_env=environment)
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertTrue(self.report.is_file())
        self.assertFalse(side_file.exists())

    def test_dependency_change_records_prelaunch_failure_without_starting_wrapper(self):
        self.assert_sandbox_available()
        dependency = self.root / "delegated adapter.py"
        dependency.write_text("original")
        config = json.loads(self.config_path.read_text())
        config["cli_adapter_settings"]["fixture"]["files"] = [str(dependency)]
        self.config_path.write_text(json.dumps(config))
        (self.root / "brief with spaces.md").write_text("implement the fixture")
        probe = self.invoke("probe")
        self.assertEqual(probe.returncode, 0, probe.stderr)
        claim_path = Path(self.pending_claim["claim_path"])
        original_events = self.events.read_bytes()
        dependency.write_text("changed")

        run = self.invoke("run")
        self.assertEqual(run.returncode, 2, run.stderr)
        self.assertIn("effective settings changed after probe", run.stderr)
        self.assertEqual(self.events.read_bytes(), original_events)
        stage = json.loads(claim_path.read_text())["stages"]["run"]
        self.assertEqual(stage["status"], "failed")
        self.assertTrue(stage["execution_recorded"])
        self.assertIsNone(stage["exit_status"])
        self.assertNotIn("adapter_process_group", stage)

    def test_dependency_changed_during_sandbox_check_never_launches_wrapper(self):
        self.assert_sandbox_available()
        dependency = self.root / "delegated adapter.py"
        dependency.write_text("original")
        config = json.loads(self.config_path.read_text())
        config["cli_adapter_settings"]["fixture"]["files"] = [str(dependency)]
        self.config_path.write_text(json.dumps(config))
        (self.root / "brief with spaces.md").write_text("implement the fixture")
        probe = self.invoke("probe")
        self.assertEqual(probe.returncode, 0, probe.stderr)
        claim_path = Path(self.pending_claim["claim_path"])
        original_events = self.events.read_bytes()
        driver_entry = self.root / "driver after sandbox check.py"
        driver_entry.write_text(f"""
from pathlib import Path
import runpy

namespace = runpy.run_path({str(SCRIPT)!r})
main = namespace["main"]
verify_sandbox = main.__globals__["verify_sandbox"]

def verify_then_change(routing_root):
    verify_sandbox(routing_root)
    Path({str(dependency)!r}).write_text("changed during verification")

main.__globals__["verify_sandbox"] = verify_then_change
raise SystemExit(main())
""")
        run = self.invoke("run", driver_entry=driver_entry)
        self.assertEqual(run.returncode, 2, run.stderr)
        self.assertIn("effective settings changed before launch", run.stderr)
        self.assertEqual(dependency.read_text(), "changed during verification")
        self.assertEqual(self.events.read_bytes(), original_events)
        stage = json.loads(claim_path.read_text())["stages"]["run"]
        self.assertEqual(stage["status"], "failed")
        self.assertNotIn("adapter_process_group", stage)

    def test_review_batch_pin_rejects_a_changed_wrapper_or_effective_setting(self):
        self.assert_sandbox_available()
        lane = "cli:fixture/model/v1"
        options = {"role": "reviewer", "sandbox": "read-only", "lane": lane}
        dependency = self.root / "backend settings.txt"
        dependency.write_text("original")
        config = json.loads(self.config_path.read_text())
        config["cli_adapter_settings"]["fixture"]["files"] = [str(dependency)]
        self.config_path.write_text(json.dumps(config))
        (self.root / "brief with spaces.md").write_text("review the fixture")

        unpinned = subprocess.run(
            [sys.executable, str(SCRIPT), "claim", "--config", str(self.config_path),
             "--repo", str(self.repo), "--role", "reviewer", "--work-item", "unpinned", "--lane", lane],
            text=True, capture_output=True, check=False,
        )
        self.assertEqual(unpinned.returncode, 2, unpinned.stderr)
        self.assertIn("reviewer claims require the review batch's --expected-identity", unpinned.stderr)

        initial = self.identify(lane)
        self.assertEqual(initial.returncode, 0, initial.stderr)
        frozen = json.loads(initial.stdout)["identity_sha256"]
        first_probe = self.invoke("probe", expected_identity=frozen, **options)
        self.assertEqual(first_probe.returncode, 0, first_probe.stderr)
        previous_claim = Path(self.pending_claim["claim_path"])
        first_run = self.invoke("run", **options)
        self.assertEqual(first_run.returncode, 0, first_run.stderr)
        first_report = self.report
        previous_record = previous_claim.read_bytes()
        self.assertEqual(json.loads(previous_record)["adapter_identity_sha256"], frozen)
        self.assertEqual(first_report.read_text(), "fixture role output\n")
        claims_directory = previous_claim.parent
        for affected in (self.executable, dependency):
            with self.subTest(changed=affected.name):
                original = affected.read_bytes()
                affected.write_bytes(original + b"\n# changed during the batch\n")
                resumed = self.identify(lane, frozen)
                self.assertEqual(resumed.returncode, 2, resumed.stderr)
                self.assertIn(lane, resumed.stderr)
                self.assertIn("adapter identity changed", resumed.stderr)
                queued = self.invoke("probe", expected_identity=frozen, **options)
                self.assertEqual(queued.returncode, 2, queued.stderr)
                self.assertIn("adapter identity changed", queued.stderr)
                self.assertEqual(list(claims_directory.iterdir()), [previous_claim])
                self.assertEqual(previous_claim.read_bytes(), previous_record)
                self.assertEqual(first_report.read_text(), "fixture role output\n")
                affected.write_bytes(original)
        resumed = self.identify(lane, frozen, {"FIXTURE_BASE_URL": "https://changed.invalid"})
        self.assertEqual(resumed.returncode, 2, resumed.stderr)
        self.assertIn("adapter identity changed", resumed.stderr)

        probe = self.invoke("probe", expected_identity=frozen, **options)
        self.assertEqual(probe.returncode, 0, probe.stderr)
        second_claim = Path(self.pending_claim["claim_path"])
        dependency.write_text("changed after the pinned probe")
        run = self.invoke("run", **options)
        self.assertEqual(run.returncode, 2, run.stderr)
        self.assertIn("adapter identity changed", run.stderr)
        self.assertNotIn("fixture event: ", run.stderr)
        run_stage = json.loads(second_claim.read_text())["stages"]["run"]
        self.assertEqual(run_stage["status"], "failed")
        self.assertNotIn("adapter_process_group", run_stage)
        self.assertFalse(self.report.exists())

    def test_missing_report_still_records_completed_process_as_failed(self):
        self.assert_sandbox_available()
        environment = {"FIXTURE_METADATA_MODE": "missing-report"}
        (self.root / "brief with spaces.md").write_text("implement the fixture")
        probe = self.invoke("probe", extra_env=environment)
        self.assertEqual(probe.returncode, 0, probe.stderr)
        claim_path = Path(self.pending_claim["claim_path"])
        run = self.invoke("run", extra_env=environment)
        self.assertEqual(run.returncode, 2, run.stderr)
        self.assertIn("completed worker report", run.stderr)
        self.assertFalse(self.report.exists())
        stage = json.loads(claim_path.read_text())["stages"]["run"]
        self.assertEqual(stage["status"], "failed")
        self.assertEqual(stage["exit_status"], 0)
        self.assertTrue(stage["execution_recorded"])
        self.assertGreater(stage["adapter_process_group"], 0)

    def test_interrupted_stage_settlement_requires_both_known_processes_to_exit(self):
        self.assert_sandbox_available()
        probe = self.invoke("probe")
        self.assertEqual(probe.returncode, 0, probe.stderr)
        claim_path = Path(self.pending_claim["claim_path"])
        claim = json.loads(claim_path.read_text())
        stage = claim["stages"]["probe"]
        settle = [
            sys.executable, str(SCRIPT), "settle-stage", "--repo", str(self.repo), "--role", "implementer",
            "--work-item", claim["work_item"], "--claim-id", claim["claim_id"], "--stage", "probe",
            "--authorization-id", stage["authorization_id"],
        ]
        stage = {"authorization_id": stage["authorization_id"], "status": "consumed", "released": True}
        claim["stages"]["probe"] = stage
        fixture_process = [sys.executable, "-c", "import time; time.sleep(30)"]
        with subprocess.Popen(fixture_process) as driver, subprocess.Popen(
            fixture_process, start_new_session=True,
        ) as adapter:
            try:
                stage["driver_handle"] = driver.pid
                claim_path.write_text(json.dumps(claim))
                unknown = subprocess.run(settle, text=True, capture_output=True, check=False)
                self.assertEqual(unknown.returncode, 2, unknown.stderr)
                self.assertIn("never recorded", unknown.stderr)
                stage["adapter_process_group"] = adapter.pid
                claim_path.write_text(json.dumps(claim))
                driver.terminate()
                driver.wait(timeout=5)
                live = subprocess.run(settle, text=True, capture_output=True, check=False)
                self.assertEqual(live.returncode, 2, live.stderr)
                self.assertIn("absence must both be verified", live.stderr)
                self.assertEqual(json.loads(claim_path.read_text())["stages"]["probe"]["status"], "consumed")
            finally:
                driver.terminate()
                adapter.terminate()
                driver.wait(timeout=5)
                adapter.wait(timeout=5)
        settled = subprocess.run(settle, text=True, capture_output=True, check=False)
        self.assertEqual(settled.returncode, 0, settled.stderr)
        self.assertEqual(json.loads(claim_path.read_text())["stages"]["probe"]["status"], "failed")
        self.assertEqual(len(self.events.read_text().splitlines()), 1)

    def test_model_mismatch_after_write_preserves_files_and_blocks_acceptance(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("implement the fixture")
        environment = {"FIXTURE_METADATA_MODE": "mismatch-on-run"}
        probe = self.invoke("probe", extra_env=environment)
        self.assertEqual(probe.returncode, 0, probe.stderr)
        claim_path = Path(self.pending_claim["claim_path"])
        run = self.invoke("run", extra_env=environment)
        self.assertNotEqual(run.returncode, 0)
        self.assertIn("observed_model_id", run.stderr)
        self.assertEqual(self.authorized_file.read_text(), "after\n")
        claim = json.loads(claim_path.read_text())
        self.assertEqual(claim["route"], "cli:fixture/model/v1")
        self.assertEqual(claim["stages"]["run"]["status"], "failed")
        attempt = Path(claim["attempt_dir"])
        self.assertFalse((attempt / "accepted-report.md").exists())
        intent = attempt / "finalization-intent.json"
        intent.write_text(json.dumps({
            "schema_version": 1,
            "outcome": "failed",
            "claim_id": claim["claim_id"],
            "role": "implementer",
            "work_item": claim["work_item"],
            "route": claim["route"],
            "repo": claim["repo"],
            "expected_head": claim["head_sha"],
            "report": {"source": str(self.report), "sha256": hashlib.sha256(self.report.read_bytes()).hexdigest()},
            "checkpoint": {
                "path": str(self.state_file),
                "expected_sha256": hashlib.sha256(self.state_file.read_bytes()).hexdigest(),
                "content": "blocked pending reconciliation\n",
            },
            "commit": {"enabled": False, "paths": [], "message": ""},
        }))
        failed = subprocess.run(
            [sys.executable, str(SCRIPT), "finalize", "--intent", str(intent)],
            text=True, capture_output=True, check=False,
        )
        self.assertEqual(failed.returncode, 0, failed.stderr)
        self.assertTrue((attempt / "terminal-report.md").is_file())
        self.assertFalse((attempt / "accepted-report.md").exists())

        def claim_again(model, *retry):
            return subprocess.run(
                [sys.executable, str(SCRIPT), "claim", "--config", str(self.config_path),
                 "--repo", claim["repo"], "--role", "implementer", "--work-item", claim["work_item"],
                 "--lane", model, "--write-path", str(self.authorized_file), *retry],
                text=True, capture_output=True, check=False,
            )

        self.assertIn("explicit retry", claim_again(claim["route"]).stderr)
        retry = ("--retry-claim", claim["claim_id"])
        self.assertIn("saved route changed", claim_again("cli:fixture/different", *retry).stderr)
        self.assertIn("not been reconciled", claim_again(claim["route"], *retry).stderr)
        self.authorized_file.write_text("before\n")
        retried = claim_again(claim["route"], *retry)
        self.assertEqual(retried.returncode, 0, retried.stderr)
        replacement = json.loads(retried.stdout)
        self.assertEqual(replacement["route"], claim["route"])
        self.assertNotEqual(replacement["claim_id"], claim["claim_id"])
        self.assertTrue((attempt / "terminal-report.md").is_file())

    def test_unknown_adapter_blocks_with_original_route(self):
        result = self.resolve("cli:missing/model-x", {"cli_adapters": {}})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cli:missing/model-x", result.stderr)
        self.assertIn("correction", result.stderr.lower())

    def test_missing_or_non_executable_path_blocks(self):
        for path in (str(self.root / "missing"), str(self.root)):
            with self.subTest(path=path):
                result = self.resolve("cli:local/model-x", {"cli_adapters": {"local": path}})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("cli:local/model-x", result.stderr)
        self.executable.chmod(0o600)
        self.assertTrue(self.executable.is_file())
        result = self.resolve("cli:local/model-x", {"cli_adapters": {"local": str(self.executable)}})
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("must name an executable file", result.stderr)

    def test_invalid_config_blocks_active_route(self):
        self.config_path.write_text("{")

        result = self.resolve("cli:local/model-x")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cli:local/model-x", result.stderr)
        self.assertIn("config", result.stderr.lower())

    def test_codex_adapter_cannot_be_redefined(self):
        result = self.resolve("cli:codex/model-x", {"cli_adapters": {"codex": str(self.executable)}})

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"status": "no-custom-adapter", "route": "cli:codex/model-x"})

    def test_codex_route_ignores_invalid_config(self):
        self.config_path.write_text("not json")

        result = self.resolve("cli:codex/gpt-native")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"status": "no-custom-adapter", "route": "cli:codex/gpt-native"})

    def test_relative_executable_path_blocks(self):
        relative_path = os.path.relpath(self.executable, Path.cwd())

        result = self.resolve("cli:local/model-x", {"cli_adapters": {"local": relative_path}})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cli:local/model-x", result.stderr)
        self.assertIn("absolute", result.stderr.lower())

    def test_whitespace_only_route_components_block(self):
        for lane in ("cli:   /model", "cli:local/   "):
            with self.subTest(lane=lane):
                result = self.resolve(lane, {"cli_adapters": {"local": str(self.executable)}})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(lane, result.stderr)

    def test_inactive_routes_do_not_inspect_config(self):
        self.config_path.write_text("not json")

        for lane in ("inline", "session", "codex:gpt-native", "claude:sonnet"):
            with self.subTest(lane=lane):
                result = self.resolve(lane)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout), {"status": "no-custom-adapter", "route": lane})

    def assert_consumed_authorization_blocks(self, launched, claim_path, stage):
        original = claim_path.read_bytes()
        events_before = self.events.read_bytes()
        claim = json.loads(original)
        completed = claim["stages"][stage]
        # Simulate consumption before the driver records any execution outcome.
        consumed = {
            "authorization_id": completed["authorization_id"],
            "status": "consumed",
            "driver_handle": None,
            "released": False,
            "baseline": completed["post_baseline"],
        }
        claim["stages"][stage] = consumed
        replacement = claim_path.with_suffix(".fixture-replacement")

        def replace_claim(data):
            replacement.write_bytes(data)
            replacement.replace(claim_path)

        try:
            replace_claim(json.dumps(claim).encode())
            with subprocess.Popen(
                [*launched.args, "--barrier-timeout", "3"],
                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                env={**os.environ, "FIXTURE_EVENTS": str(self.events), "FIXTURE_MODEL_TOKEN": "fixture-secret"},
            ) as driver:
                waiting = json.loads(driver.stderr.readline())
                self.assertEqual(waiting["driver_handle"], driver.pid)
                consumed["driver_handle"] = driver.pid
                consumed["released"] = True
                replace_claim(json.dumps(claim).encode())
                _, stderr = driver.communicate(timeout=5)
                self.assertEqual(driver.returncode, 2, stderr)
                self.assertIn("launch authorization is stale, consumed, or unbound", stderr)
                self.assertNotIn("fixture event: ", stderr)
            self.assertEqual(json.loads(claim_path.read_text())["stages"][stage], consumed)
            self.assertEqual(self.events.read_bytes(), events_before)
        finally:
            replace_claim(original)

    def test_probe_and_run_preserve_argv_cwd_environment_and_model(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("implement fixture task\n")

        probe = self.invoke("probe")
        self.assertEqual(probe.returncode, 0, probe.stderr)
        self.assertIn("fixture warning", probe.stderr)
        self.assertTrue(self.receipt.is_file())
        self.assert_consumed_authorization_blocks(probe, Path(self.pending_claim["claim_path"]), "probe")
        run = self.invoke("run")
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertEqual(run.stdout, "fixture role output\n")
        events = [json.loads(line) for line in self.events.read_text().splitlines()]
        self.assertEqual([event["action"] for event in events], ["probe", "run"])
        self.assertEqual(events[0]["model"], "model/v1")
        self.assertEqual(events[1]["cwd"], str(self.repo.resolve()))
        self.assertTrue(events[1]["credential_received"])
        self.assertNotIn("fixture-secret", run.stdout + run.stderr)
        self.assertNotIn("fixture-secret", self.receipt.read_text())
        self.assertEqual(events[1]["brief"], str((self.root / "brief with spaces.md").resolve()))
        self.assertEqual(events[1]["argv"][0:5], ["run", "--model", "model/v1", "--repo", str(self.repo.resolve())])
        self.assertIn(str(self.executable.resolve()), str(self.config_path.read_text()))
        self.assertEqual(self.authorized_file.read_text(), "after\n")
        self.assertEqual(self.report.read_text(), "fixture report\n")

    def test_launcher_cannot_alter_coordinator_controls_or_redirect_writes(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("implement fixture task\n")
        protected_files = (self.lock_file, self.claim_file, self.state_file, self.git_admin_file, self.redirect)
        attacks = json.dumps([str(path) for path in protected_files])
        rename_dirs = json.dumps([str(path) for path in self.control_paths])
        environment = {"FIXTURE_ATTACK_PATHS": attacks, "FIXTURE_RENAME_DIRS": rename_dirs}
        self.assertEqual(self.invoke("probe", extra_env=environment).returncode, 0)
        result = self.invoke("run", extra_env=environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        event = [json.loads(line) for line in self.events.read_text().splitlines()][-1]
        self.assert_denied_operations(event, protected_files, self.control_paths)
        self.assertEqual(self.lock_file.read_text(), "lock\n")
        self.assertEqual(self.claim_file.read_text(), "claim\n")
        self.assertEqual(self.state_file.read_text(), "state\n")
        self.assertEqual(self.git_admin_file.read_text(), "admin\n")
        self.assertTrue(self.redirect.is_symlink())

    def test_symlink_cannot_be_authorized_as_a_task_file(self):
        result = self.invoke("probe", write_paths=(self.redirect,))

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlink", result.stderr.lower())
        self.assertEqual(self.events.read_text(), "")

    def test_undeclared_model_or_sandbox_override_blocks_before_launch(self):
        for name in ("FIXTURE_MODEL_OVERRIDE", "FIXTURE_SANDBOX_OVERRIDE"):
            with self.subTest(name=name):
                result = self.invoke("probe", extra_env={name: "unexpected"})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(name, result.stderr)
                self.assertEqual(self.events.read_text(), "")

    def test_probe_blocks_bad_metadata_and_nonzero_exit_after_launch(self):
        self.assert_sandbox_available()
        diagnostics = {
            "missing": "did not return bounded schema-v1 backend metadata",
            "malformed": "malformed backend metadata",
            "mismatch": "backend metadata mismatch for observed_model_id",
            "nonzero": "Adapter exited with status 7",
            "denied": "backend metadata mismatch for permission_mode",
            "missing-source": "authoritative backend-response or backend-event source",
            "invalid-source": "authoritative backend-response or backend-event source",
            "object-source": "authoritative backend-response or backend-event source",
            "array-source": "authoritative backend-response or backend-event source",
            "boolean-version": "backend metadata mismatch for schema_version",
            "fractional-version": "backend metadata mismatch for schema_version",
        }
        for mode, diagnostic in diagnostics.items():
            with self.subTest(mode=mode):
                result = self.invoke("probe", extra_env={"FIXTURE_METADATA_MODE": mode})
                self.assertEqual(result.returncode, 7 if mode == "nonzero" else 2, result.stderr)
                self.assertIn(diagnostic, result.stderr)
                events = [json.loads(line) for line in self.events.read_text().splitlines()]
                self.assertEqual([event["action"] for event in events], ["probe"])
                stage = json.loads(Path(self.pending_claim["claim_path"]).read_text())["stages"]["probe"]
                self.assertEqual(stage["status"], "failed")
                self.assertTrue(stage["execution_recorded"])

    def test_rejected_run_metadata_preserves_role_output_channels(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("review the fixture")
        diagnostics = {
            "malformed-on-run": "malformed backend metadata",
            "mismatch-on-run": "backend metadata mismatch for observed_model_id",
        }
        for mode, diagnostic in diagnostics.items():
            with self.subTest(mode=mode):
                options = {"role": "reviewer", "sandbox": "read-only",
                           "extra_env": {"FIXTURE_METADATA_MODE": mode}}
                probe = self.invoke("probe", **options)
                self.assertEqual(probe.returncode, 0, probe.stderr)
                claim_path = Path(self.pending_claim["claim_path"])
                run = self.invoke("run", **options)
                self.assertEqual(run.returncode, 2, run.stderr)
                self.assertEqual(run.stdout, "fixture role output\n")
                self.assertNotIn("fixture role output", run.stderr)
                self.assertIn("fixture warning", run.stderr)
                self.assertIn(diagnostic, run.stderr)
                self.assertFalse(self.report.exists())
                stage = json.loads(claim_path.read_text())["stages"]["run"]
                self.assertEqual(stage["status"], "failed")
                self.assertTrue(stage["execution_recorded"])
                self.assertNotIn("report_sha256", stage)

    def test_terminated_run_preserves_role_output_channels(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("review the fixture")
        short_driver = self.root / "short timeout driver.py"
        short_driver.write_text(f"""
import runpy

main = runpy.run_path({str(SCRIPT)!r})["main"]
main.__globals__["INVOCATION_TIMEOUT_SECONDS"] = 0.8
raise SystemExit(main())
""")
        for mode, exit_code, diagnostic in (
            ("timeout-on-run", 124, "exceeded its time limit"),
            ("lingering-child-on-run", 2, "left a child process running"),
        ):
            with self.subTest(mode=mode):
                options = {"role": "reviewer", "sandbox": "read-only",
                           "extra_env": {"FIXTURE_METADATA_MODE": mode}}
                probe = self.invoke("probe", **options)
                self.assertEqual(probe.returncode, 0, probe.stderr)
                run = self.invoke("run", driver_entry=short_driver if exit_code == 124 else None, **options)
                self.assertEqual(run.returncode, exit_code, run.stderr)
                self.assertEqual(run.stdout, "fixture role output\n")
                self.assertNotIn("fixture role output", run.stderr)
                self.assertIn("fixture warning", run.stderr)
                self.assertIn(diagnostic, run.stderr)
                self.assertFalse(self.report.exists())

    def test_declared_variables_cannot_override_fixed_runtime(self):
        self.assert_sandbox_available()
        original = json.loads(self.config_path.read_text())
        for key in ("environment", "credentials"):
            for name in ("HOME", "TMPDIR", "PATH", "LANG"):
                with self.subTest(key=key, name=name):
                    config = json.loads(json.dumps(original))
                    config["cli_adapter_settings"]["fixture"][key].append(name)
                    self.config_path.write_text(json.dumps(config))
                    result = self.invoke("probe")
                    self.assertEqual(result.returncode, 2, result.stderr)
                    self.assertIn(f"fixed runtime setting {name}", result.stderr)
                    self.assertEqual(self.events.read_text(), "")
                    stage = json.loads(Path(self.pending_claim["claim_path"]).read_text())["stages"]["probe"]
                    self.assertEqual(stage["status"], "failed")
                    self.assertNotIn("adapter_process_group", stage)

    def test_run_rejects_changed_executable_or_declared_settings(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("implement fixture task\n")
        self.assertEqual(self.invoke("probe").returncode, 0)
        original = self.executable.read_text()
        self.executable.write_text(original + "# changed after probe\n")
        changed = self.invoke("run")
        self.assertNotEqual(changed.returncode, 0)
        self.assertIn("changed", changed.stderr.lower())
        self.executable.write_text(original)

        self.events.write_text("")
        self.receipt.unlink()
        self.assertEqual(self.invoke("probe", extra_env={"FIXTURE_BASE_URL": "https://gateway-one.invalid"}).returncode, 0)
        changed = self.invoke("run", extra_env={"FIXTURE_BASE_URL": "https://gateway-two.invalid"})
        self.assertNotEqual(changed.returncode, 0)
        self.assertIn("settings changed", changed.stderr.lower())
        self.assertEqual(len(self.events.read_text().splitlines()), 1)

    def assert_denied_operations(self, event, files, directories=()):
        expected = [(str(path), operation) for path in files
                    for operation in ("write", "unlink", "rename", "replace")]
        expected.extend((str(path), "rename-parent") for path in directories)
        self.assertCountEqual(
            [(attempt["path"], attempt["operation"]) for attempt in event["attempts"]],
            expected,
        )
        self.assertTrue(all(attempt["denied"] for attempt in event["attempts"]))

    def test_tester_keeps_workspace_write_without_coordinator_writes(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("test fixture task\n")
        protected = (self.lock_file, self.claim_file, self.state_file, self.git_admin_file)
        attacks = json.dumps([str(path) for path in protected])
        rename_dirs = json.dumps([str(path) for path in self.control_paths])
        environment = {"FIXTURE_ATTACK_PATHS": attacks, "FIXTURE_RENAME_DIRS": rename_dirs}
        self.assertEqual(self.invoke("probe", role="tester", sandbox="workspace-write", extra_env=environment).returncode, 0)
        result = self.invoke("run", role="tester", sandbox="workspace-write", extra_env=environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.authorized_file.read_text(), "after\n")
        event = [json.loads(line) for line in self.events.read_text().splitlines()][-1]
        self.assert_denied_operations(event, protected, self.control_paths)
        self.assertEqual(self.lock_file.read_text(), "lock\n")
        self.assertEqual(self.claim_file.read_text(), "claim\n")
        self.assertEqual(self.state_file.read_text(), "state\n")
        self.assertEqual(self.git_admin_file.read_text(), "admin\n")

    def test_tester_can_run_with_only_its_assigned_report_destination(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("test fixture task")
        probe = self.invoke("probe", role="tester", write_paths=())
        self.assertEqual(probe.returncode, 0, probe.stderr)
        run = self.invoke("run", role="tester", write_paths=())
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertEqual(self.authorized_file.read_text(), "before\n")
        self.assertEqual(self.report.read_text(), "fixture report\n")

    def test_reviewer_workspace_stays_read_only(self):
        self.assert_sandbox_available()
        (self.root / "brief with spaces.md").write_text("review fixture task\n")
        attack = json.dumps([str(self.authorized_file)])
        self.assertEqual(self.invoke("probe", role="reviewer", sandbox="read-only", extra_env={"FIXTURE_ATTACK_PATHS": attack}).returncode, 0)
        claim_path = Path(self.pending_claim["claim_path"])
        result = self.invoke("run", role="reviewer", sandbox="read-only", extra_env={"FIXTURE_ATTACK_PATHS": attack})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.authorized_file.read_text(), "before\n")
        self.assertEqual(self.report.read_bytes(), result.stdout.encode())
        event = next(json.loads(line.removeprefix("fixture event: ")) for line in result.stderr.splitlines()
                     if line.startswith("fixture event: "))
        self.assert_denied_operations(event, (self.authorized_file,))
        claim = json.loads(claim_path.read_text())
        intent = Path(claim["attempt_dir"]) / "finalization-intent.json"
        intent.write_text(json.dumps({
            "schema_version": 1,
            "outcome": "accepted",
            "claim_id": claim["claim_id"],
            "role": "reviewer",
            "work_item": claim["work_item"],
            "route": claim["route"],
            "repo": claim["repo"],
            "expected_head": claim["head_sha"],
            "report": {"source": str(self.report), "sha256": hashlib.sha256(self.report.read_bytes()).hexdigest()},
            "checkpoint": None,
            "commit": {"enabled": False, "message": "", "paths": []},
        }))
        acceptance = subprocess.run([sys.executable, str(SCRIPT), "finalize", "--intent", str(intent)],
                                    text=True, capture_output=True, check=False)
        self.assertEqual(acceptance.returncode, 0, acceptance.stderr)
        self.assertEqual((intent.parent / "accepted-report.md").read_bytes(), result.stdout.encode())
        self.assertEqual(self.state_file.read_text(), "state\n")


if __name__ == "__main__":
    unittest.main()
