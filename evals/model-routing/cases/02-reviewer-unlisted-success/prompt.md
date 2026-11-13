You are evaluating a Codex native model-routing decision for dev-flow. Invoke the plugin skill `dev-flow:review`. Before deciding, use the loaded plugin's own skill files to resolve and read its referenced `references/model-routing.md`; follow the plugin's own reference path from the skill/plugin location. Use the runtime-resolved plugin location supplied by the invoked skill or command, including its expanded absolute path; this host-provided path is authoritative, not an invented machine-specific path. Do not invent or hardcode paths. Read the referenced source directly at the supplied plugin location, not through broad globs or paths relative to the fixture working directory. The reference text must inform your decision.

If you cannot locate or read the plugin-owned reference, say so explicitly, do not guess from memory or this prompt, and do not claim a successful evaluation. Do not perform real implementation/review work or make a real native subagent dispatch: the state and tool outcome below are narrated test evidence. Give only the routing decision based on the source contract and fixture.

Scenario:
The config contains `codex_reviewer_model: "vendor/model-zeta"`. The user requests the reviewer pass.

Narrated native tool evidence: `model` accepts any string; there is no enforced enum or allowlist. Displayed examples are `vendor/model-alpha` and `vendor/model-beta` only. The exact pin `vendor/model-zeta` is accepted and the narrated dispatch/completion result is successful.

State whether the exact route should dispatch, has been rejected, or must be blocked before dispatch. Explain the causal ordering, exact model, context isolation when dispatch is permitted/attempted, progress state, and next action. Ground the decision in the plugin reference you read (name the relevant section and quote or accurately paraphrase its rule).
