Invoke `dev-flow:test` to load the plugin-owned guidance for this narrated evaluation. Use the runtime-resolved plugin location supplied by the invoked skill or command, including its expanded absolute engine path. Resolve reference links from their owning file, not the fixture working directory, and read the required source directly. This source-loading step is allowed before the task below; do not start or resume a real workflow, inspect a real target repository, or dispatch workers. The task below overrides unrelated workflow actions. If a required source cannot be read, report that failure instead of inventing its contents.

Run the standalone `test` skill using the narrated environment below. Prepare the tester dispatch brief and report the supplied simulated result. This fixture is not a real dispatch: do not claim that a subagent ran or that you inspected a real repository.

Narrated environment:
- No dev-flow state file exists. The user's selected Tester lane is `session` (fresh native subagent).
- Repository: `/workspace/csv-service`; Head SHA: `abc123456789`; Base ref: `main`; Base SHA: `def987654321`.
- The diff adds CSV export. Test contract: quoted commas, embedded quotes, and empty cells must round-trip correctly.
- Full test-suite command: `pnpm vitest run`; lint command: `pnpm lint`.
- Relevant working tree is clean. No plan file exists because this is a standalone test request.
- Simulated test and lint results: the full suite passed, 48 tests total, including the three changed CSV cases; lint passed with no warnings. Honesty scan found no asserts-nothing, mocks-the-subject, tautological, or always-pass tests.
- Simulated completion time: 2026-11-06 15:10 UTC.
- Report path: `docs/features/.test/csv-service/test-report.md`.

Prepare the dispatch brief that the skill requires, including the actual contents of the plugin-root `references/output-style.md` for the fresh agent. Make clear that the result below is simulated fixture data. Then write a complete simulated report to the required report path and give the green/red verdict with a one-line summary and counts. Do not claim actual dispatch or command execution. Create the report file in the eval workspace and describe it as a simulated report.
