You are evaluating a dev-flow routing contract. Invoke `dev-flow:review`. Before deciding, follow the loaded plugin's own references to read `references/model-routing.md` and the directly relevant skill contract. Resolve paths from the plugin location; do not use machine-specific absolute paths.

If the source cannot be located or read, say so and do not guess or claim a successful evaluation. The scenario is narrated fixture evidence, not hidden tool calls. Do not perform real work or dispatch.

Scenario:
Host: Claude Code. Saved Reviewer is `session`; standalone red-team behavior is also `session`. `reviewers` is `{"red_team":["cli:codex/model-x","claude:sonnet"],"main_review":["session","cli:codex/model-y"]}`. The Codex-only map is malformed but inactive. `plan_review` is absent. Both CLI reviewers run read-only and return complete report text in output; the driver captures that text. Main group has two concurrent members. Narrated fixtures provide distinct per-member paths: reviewer-1 brief/output/report and reviewer-2 brief/output/report. No actual tools are called.

Resolve the three steps, explain CLI report transport and unique paths, persistence without editorial judgment, and how absent steps retain legacy behavior. Ground the answer in source.
