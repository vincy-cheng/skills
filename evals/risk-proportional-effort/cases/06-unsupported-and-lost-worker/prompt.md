You are executing dev-flow steps on four situations. Answer from the narration only; do not run external tooling.

Situation A: the user confirms `Implementer context: shared` on the `cli:codex/<model>` lane. The lane re-runs the CLI tool per task with the same model; the CLI has no conversation continuation between runs.

Situation B: a `shared` run mid-execute; the worker became unreachable after task 2 (its conversation cannot be reached). Task 3 is unchecked. The task 2 report and a dirty diff exist.

Situation C: after many follow-ups, the shared worker's context has grown beyond what the tool reliably handles and follow-up quality keeps degrading.

Situation D: a run's state file has `Implementer context: pooled` (a value the contract does not define).

Questions:

1. For situation A, is `shared` actually available on this lane? What happens, and what is explicitly offered?
2. For situation B, what is preserved before anything else, what is presented to the user, and what must not happen (three specific things)?
3. For situation C, what is the handling, and how does it differ from a BLOCKED model rejection?
4. For situation D, what does the run do — proceed, default to per-task, or stop? Quote the rule.

Do not run any external tooling. Answer the four questions only.
