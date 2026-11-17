You are executing dev-flow steps on three situations. Answer from the narration only; do not run external tooling.

Situation A (legacy state): a run's state file predates the Implementer context field entirely. Its Roles block says `Implementer: claude:haiku`. The run is resuming mid-execute.

Situation B (saved choices): a run confirmed `Implementer context: shared` and a pinned lightweight model at step 5. Since then, the repo's `.dev-flow/config.json` was edited to a different implementer default, and the run is resuming.

Situation C (repair escalation): a run classified small (self-check path) with 2 tasks; a post-PR finding added a third and fourth task touching a new integration surface with fresh architecture questions.

Questions:

1. What context lifecycle does situation A run with, and may the file be migrated/rewritten? (There is no confirmed pick; what must NOT be claimed?)
2. What context and model does situation B use on resume? Is the config change adopted? May the picks be re-asked?
3. Does situation C keep the self-check path? What must happen before the new work continues, and what cannot be skipped?
4. Under the context rules, what is the one sanctioned fallback when a named agent type 404s, and what must accompany it?

Do not run any external tooling. Answer the four questions only.
