You are evaluating a dev-flow routing contract. Invoke `dev-flow:review`. Before deciding, follow the loaded plugin's own references to read `references/model-routing.md` and the directly relevant skill contract. Resolve paths from the plugin location; do not use machine-specific absolute paths.

If the source cannot be located or read, say so and do not guess or claim a successful evaluation. The scenario is narrated fixture evidence, not hidden tool calls. Do not perform real work or dispatch.

Scenario:
Host: Codex. `.dev-flow/config.json` contains `codex_reviewer_model: "legacy/default"` and `codex_reviewers: {"red_team":["model-a","model-b"],"plan_review":["model-c"],"focused_review":["model-d","model-e","model-f"]}`. The `reviewers` object contains malformed Claude-only values and is inactive here. Codex host concurrency is 2. A high-risk plan review is requested, then a high-risk focused review. Tool capability evidence permits arbitrary exact string `model` values; no enforced enum excludes them. Narrated dispatch evidence says all reviewers return complete reports and pass. No native calls are to be made.

Explain selected routes/counts and fallback, dispatch batches/queue, context/report isolation, and completion. Do not invent additional tool outcomes.
