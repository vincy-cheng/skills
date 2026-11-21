Invoke `dev-flow:execute-tasks` first, then `dev-flow:new-feature` and `dev-flow:plan` for the resume and plan-review questions. From the runtime plugin base returned or resolved by those Skill invocations, make separate Read calls on `skills/execute-tasks/SKILL.md`, `references/model-routing.md`, `skills/new-feature/SKILL.md`, and `skills/plan/SKILL.md`; do not resolve paths from the target repository. Wait for each Read result before the next Read. Allow only Skill and Read for guidance. This is narrated only: do not run commands, dispatch workers or reviewers, modify files or state, or perform other operational actions.

Situation A (legacy state): a run's state file predates the Implementer context field entirely. Its Roles block says `Implementer: claude:haiku`. The run is resuming mid-execute.

Situation B (saved choices): a run confirmed `Implementer context: shared` and a pinned lightweight model at step 5. Since then, the repo's `.dev-flow/config.json` was edited to a different implementer default, and the run is resuming.

Situation C (repair escalation): a run classified small (self-check path) with 2 tasks; a post-PR finding added a third and fourth task touching a new integration surface with fresh architecture questions.

Questions:

1. What context lifecycle does situation A run with, and may the file be migrated/rewritten? (There is no confirmed pick; what must NOT be claimed?)
2. What context and model does situation B use on resume? Is the config change adopted? May the picks be re-asked?
3. Does situation C keep the self-check path? What must happen before the new work continues, and what cannot be skipped?
4. Under the context rules, what is the one sanctioned fallback when a named agent type 404s, and what must accompany it?

Do not run any external tooling. Answer the four questions only.
