You are executing the dev-flow execute-tasks skill on a run whose Roles ask confirmed Implementer lane `claude:<name>`, a pinned lightweight model, and `Implementer context: shared`. Tasks 1–2 are complete; task 3 is next. Answer from the narration only; do not run external tooling.

Before dispatching task 3's follow-up, you observe: (a) `git branch --show-current` still returns the state's Base branch; (b) `git status --short` shows an uncommitted edit to a file task 3 must also modify; (c) the plan's task 3 text mentions a function name that tasks 1–2's commit actually named differently; (d) the shared worker is reachable.

Questions:

1. May the task 3 follow-up dispatch proceed as-is? What must happen about the dirty file first?
2. The plan says one function name; HEAD says another. What wins, and what does the follow-up brief carry for it?
3. What does the follow-up brief **carry** and what does it **not re-send**? (Assume task 1–2's shared guidance was confirmed delivered and unchanged.)
4. After the worker's report: which review happens (who does it), what is committed, and does the worker's conversation replace any independent check?

Do not run any external tooling. Answer the four questions only.
