You are evaluating a dev-flow routing contract. Invoke `dev-flow:review`. Before deciding, follow the loaded plugin's own references to read `references/model-routing.md` and the directly relevant skill contract. Use the runtime-resolved plugin location supplied by the invoked skill or command, including its expanded absolute path; this host-provided path is authoritative, not an invented machine-specific path. Do not invent or hardcode paths. Read the referenced source directly at the supplied plugin location, not through broad globs or paths relative to the fixture working directory.

If the source cannot be located or read, say so and do not guess or claim a successful evaluation. The scenario is narrated fixture evidence, not hidden tool calls. Do not perform real work or dispatch.

Scenario:
Codex is active. Evaluate these independent config subcases before any dispatch: (A) `red_team: []`; (B) `plan_review: ["model-a","model-a"]`; (C) `main_review: [" "]`; (D) `focused_review: ["model-a", 7]`; (E) unknown key `final_review: ["model-a"]`; (F) active `codex_reviewers: []`; (G) valid `main_review: ["model-a"]` but the exact selected model is authoritatively unavailable; (H) valid `main_review: ["model-a"]`, with unavailable legacy `codex_reviewer_model: "old-model"` unused. In all cases inactive Claude `reviewers` may be malformed. No dispatch occurs in the fixture.

Give the routing result for each subcase, identify which fail BLOCKED without defaults and which valid override permits routing despite an unused unavailable legacy setting. Cite source.
