You are evaluating a dev-flow routing contract. Invoke `dev-flow:review`. Before deciding, follow the loaded plugin's own references to read `references/model-routing.md` and the directly relevant skill contract. Resolve paths from the plugin location; do not use machine-specific absolute paths.

If the source cannot be located or read, say so and do not guess or claim a successful evaluation. The scenario is narrated fixture evidence, not hidden tool calls. Do not perform real work or dispatch.

Scenario:
Codex is active. Evaluate these independent config subcases before any dispatch: (A) `red_team: []`; (B) `plan_review: ["model-a","model-a"]`; (C) `main_review: [" "]`; (D) `focused_review: ["model-a", 7]`; (E) unknown key `final_review: ["model-a"]`; (F) active `codex_reviewers: []`; (G) valid `main_review: ["model-a"]` but the exact selected model is authoritatively unavailable; (H) valid `main_review: ["model-a"]`, with unavailable legacy `codex_reviewer_model: "old-model"` unused. In all cases inactive Claude `reviewers` may be malformed. No dispatch occurs in the fixture.

Give the routing result for each subcase, identify which fail BLOCKED without defaults and which valid override permits routing despite an unused unavailable legacy setting. Cite source.
