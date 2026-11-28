# Custom CLI adapter acceptance

The local acceptance check runs real adapter subprocesses under macOS sandbox enforcement. A deterministic launcher supplies model events and role reports without network access. The fixture runs the implementer and tester against one disposable Git repository inside the current checkout's ignored routing directory.

## Run the local check

From the plugin checkout, use a compatible Python 3 and a host that can apply `sandbox-exec`. An outer sandbox can prevent the permission check from running. A skipped sandbox test leaves this acceptance check pending.

```sh
mkdir -p docs/features/.routing/task2-test-fixtures
TMPDIR="$PWD/docs/features/.routing/task2-test-fixtures" \
  python3 -B -m unittest discover -s tests -p test_custom_cli_adapter.py \
  -k real_run_change -k model_mismatch_after_write -k preserve_argv
```

1. The implementer probes and runs the exact slash-containing model ID. It writes only its authorized scope and report. An accepted outcome creates one task commit and leaves unrelated staged content intact.
2. The tester uses the same route in a separate claim against that commit. Its accepted report records the fixture backend and permission mode. The tester checkpoint leaves HEAD unchanged.
3. The mismatch case writes before the adapter reports a different model. The helper preserves those changes and the failed report. It requires reconciliation and an explicit retry with the original route.
4. The invocation check confirms that a matching model can pass with a warning. It checks the argument vector, working directory, and declared credential forwarding.

Run `bash tests/check.sh` for the role-site and package checks. Record the repository, HEAD, base, host, fixture route, sandbox result, and test output. Keep fixture evidence in the local run directory.

## Verify a configured backend

Follow the [adapter guide](../../references/custom-cli-adapters.md) to configure a launcher and its exact model ID. In a disposable repo, select that custom route for the implementer and the tester. Choose per-task implementer context. Use a small task that produces a real test-first report. Keep the role reports, the enforced permission evidence, and the backend-reported model ID for both attempts. Start the check only when the launcher and its backend are approved for that repo.

The local fixture proves the execution interface. Live backend acceptance requires its own evidence.
