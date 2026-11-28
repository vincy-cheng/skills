# Custom CLI adapters

Custom CLI adapters let a role use a local executable for a selected `cli:<adapter>/<exact-model-id>` route. The adapter must accept the model from the route, pass it as the effective backend model, and report the model the backend observed for that invocation. A shell alias that presets a model must not replace the requested route model.

Codex-hosted dev-flow implementer and tester roles can use a custom adapter route. Native Codex reviewer and model selection stay on the native Codex path. Built-in `cli:codex/<model>` routes remain unchanged.

## Local configuration

Add an absolute executable path to `.dev-flow/config.json`:

```json
{
  "cli_adapters": {
    "gateway": "/absolute/path/to/gateway-wrapper"
  },
  "cli_adapter_settings": {
    "gateway": {
      "environment": [],
      "credentials": ["GATEWAY_TOKEN"],
      "forbidden_environment": [],
      "files": ["/absolute/path/to/backend-adapter.py", "/absolute/path/to/backend-cli"]
    }
  }
}
```

Each adapter used for `probe` or `run` must explicitly declare `environment`, `credentials`, `forbidden_environment`, and `files` in its `cli_adapter_settings` entry. Each value is a list and may be empty. These lists identify non-secret environment settings, opaque credential variable names, environment names that must be absent, and files that affect routing. For example, a local credential name may be `GATEWAY_TOKEN`. Credential values pass to the launcher but are never logged, serialized, or hashed into evidence. Non-secret setting values and declared file contents contribute SHA-256 identities. The helper gives the launcher a clean environment. It reserves `PATH`, `HOME`, `TMPDIR`, and `LANG` for its fixed process settings and rejects those names in `environment` and `credentials`. It rejects a present disabled override before launch.

The configured executable is invoked directly with an argument vector. The helper does not parse a shell command string. It sends these arguments:

```text
probe --model MODEL --repo REPO --sandbox MODE --role ROLE \
  --metadata-fd N --settings-sha256 DIGEST --write-path PATH --report PATH

run --model MODEL --repo REPO --sandbox MODE --role ROLE \
  --metadata-fd N --settings-sha256 DIGEST --brief PATH \
  --write-path PATH --report PATH
```

`probe` and `run` use the same role mode. The driver derives that mode from the role. Implementers and testers use `workspace-write` with their exact authorized task paths. Only their `run` stage can write into the private report directory. A reviewer uses `read-only` and returns its full report on stdout for the controller to save verbatim. The driver fails before launch if macOS `sandbox-exec` cannot establish the permission boundary. An authorized new task file needs an existing canonical parent and an absent exact leaf. Only that leaf gets create and write permission. Git administrative directories, workflow state, controller paths, and unlisted workspace paths remain read-only.

Fixtures, launcher scratch, private receipts, profile files, and reports stay under the target checkout's canonical gitignored `docs/features/.routing/` tree, resolved from `--repo`. The helper installation path is never used as the scratch root. A symlinked routing root is rejected; the root must be controller-owned and not group/world-writable, while per-invocation, receipt, and report directories are private. Both stages receive an isolated runtime temp directory. The controller receipt and routing parent stay outside writable paths.

The driver supplies the metadata channel as a pipe and passes its descriptor number (`N`) to the trusted wrapper. The wrapper keeps this channel for its own report and closes it for the backend child. Do not give the backend process the metadata descriptor. The wrapper must write one JSON object and close the channel. Schema version 1 is:

```json
{
  "schema_version": 1,
  "observed_model_id": "vendor/model/revision",
  "model_id_source": "backend-response",
  "backend_id": "configured-backend",
  "role": "implementer",
  "permission_mode": "workspace-write",
  "settings_sha256": "<digest passed to the wrapper>"
}
```

`schema_version` must be the JSON integer `1`. `model_id_source` must be `backend-response` or `backend-event`. The wrapper must set it only when it reads the observed ID from an authoritative structured backend response or backend event. `backend_id` must identify that source. The fixture uses `backend_id: "fixture-recorder"`; this is stand-in evidence, not a real backend result. For a real adapter, read the model field from the backend's documented response or event stream. Never copy the requested model into the observed field.

The driver accepts metadata only when the observed model ID, source kind, backend ID, role, enforced permission mode, and settings digest match the current invocation. It stores a private probe receipt under the protected routing directory. `run` compares the executable, effective settings, role, mode, and paths with the receipt. Both stages check the executable, route configuration, and complete effective settings again after sandbox verification, immediately before starting the adapter. A stale receipt, changed executable or settings, missing or malformed metadata, missing or invalid source, mismatched model or mode, nonzero backend exit, or unavailable sandbox blocks the route. A warning on stderr does not fail an invocation that exits successfully and returns matching metadata.

`run` sends backend role output to stdout, diagnostics and warnings to stderr, and model metadata through the private pipe. The helper preserves captured output on its original channels when it rejects metadata, times out, or terminates a lingering child. Only a successful run with verified metadata can produce an accepted report. The helper propagates a nonzero backend exit status. Probe output goes to stderr, and a successful probe writes a small receipt summary to stdout. No credential values appear in receipts or diagnostics.

## Wrapper example

The shell entry point supplies the fixed backend path and forwards the driver's argument vector. In this example, the delegated adapter program implements the interface above and accepts a private `--backend` option for the backend executable it will launch. The metadata descriptor number can vary between invocations.

```sh
#!/bin/sh
set -eu
exec python3 /absolute/path/to/backend-adapter.py --backend /absolute/path/to/backend-cli "$@"
```

The adapter program must parse `--metadata-fd N`, pass the exact lane model to the backend, and close extra descriptors in the backend child. For example, Python's `subprocess.run(backend_argv, close_fds=True)` keeps the metadata pipe out of the backend process. After the backend returns, read the observed model ID from its documented response or event field and write JSON to the descriptor with `os.write(metadata_fd, json_bytes)`. Set `model_id_source` to `backend-response` or `backend-event`, and include a non-secret backend ID. Never copy the requested model into the observed field.

Keep the configured adapter executable and backend arguments fixed. List the delegated adapter program, backend executable, and any files that affect routing under `files` so a change between probe and run invalidates the receipt. Declare non-secret settings, credential variable names, and disabled overrides in local config. The trusted wrapper must keep its backend and descendants in its process group so the driver can verify termination. Do not use `eval` or let an ambient model or sandbox variable override the lane.

## OmniRoute connection guide

OmniRoute can provide a gateway for a compatible CLI. Follow its [Claude Code configuration guide](https://github.com/cheaper-inference/OmniRoute/blob/release/v3.8.55/docs/guides/CLAUDE-CODE-CONFIGURATION.md) and [CLI integrations guide](https://github.com/cheaper-inference/OmniRoute/wiki/CLI-Integrations) to configure the local connection. For Claude Code, use the gateway root URL without a `/v1` suffix and keep the token in the local process environment. Select the exact model ID enabled by that gateway.

Gateway setup only connects the backend. It does not implement this adapter interface. The configured wrapper must still forward the exact lane model and verify the backend-reported model for both probe and run. Do not invoke a user shell alias as a command string. If an alias presets a model, the wrapper must override that default with the route's model and verify the observed result.
