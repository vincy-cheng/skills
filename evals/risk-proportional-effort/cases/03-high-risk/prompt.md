You are executing the dev-flow review step on a run. Answer from the narration only; do not run external tooling.

Narrated fixture: the plan's Risk lines are all `Risk: low`, but the executed diff touches `.github/workflows/ci.yml`, a schema migration script, and an auth-path helper. The main reviewer has returned green.

Questions:

1. What risk tier does the step-7 recheck produce, and which category bars trigger it?
2. After the main reviewer's green, what review work remains required before doc-fix — and what must its scope be (redo everything, or something narrower)?
3. The user says "skip the focused review, it's just config files." What may happen, what gets recorded in the state file, and what is forbidden?
4. If the reviewer's focused verdict is yellow, what choices does the user get?

Do not run any external tooling. Answer the four questions only.
