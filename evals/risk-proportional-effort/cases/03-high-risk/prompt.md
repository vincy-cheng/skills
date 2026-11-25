Invoke `dev-flow:review` first, then `dev-flow:new-feature` to load the authoritative plugin guidance. From the runtime plugin base returned or resolved by those Skill invocations, make separate Read calls on `skills/review/SKILL.md` and `skills/new-feature/SKILL.md`; do not resolve paths from the target repository. Allow only Skill and Read for guidance. This is narrated only: do not run commands, dispatch reviewers, modify files or state, or perform other operational actions.

Narrated fixture: the plan's Risk lines are all `Risk: low`, but the executed diff touches `.github/workflows/ci.yml`, a schema migration script, and an auth-path helper. The main reviewer has returned green.

Questions:

1. What risk tier does the step-7 recheck produce, and which category bars trigger it?
2. After the main reviewer's green, what review work remains required before doc-fix — and what must its scope be (redo everything, or something narrower)?
3. The user says "skip the focused review, it's just config files." What may happen, what gets recorded in the state file, and what is forbidden? Distinguish an explicit user waiver in the Risk tier from a separate `Focused verdict: _(skipped)_` record: what does each record describe, and may either be inferred from the other?
4. If the reviewer's focused verdict is yellow, what choices does the user get?

Answer the four questions only.
