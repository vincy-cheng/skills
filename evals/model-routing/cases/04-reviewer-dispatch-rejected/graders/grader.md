---
type: llm
---
# Grader — Reviewer: exact model dispatch is rejected

Grade against the plugin-owned `references/model-routing.md`, which the prompt requires the agent to load through the relevant dev-flow skill. The scenario is narrated evidence, not a transcript of hidden tool calls. Be strict and binary. A response that cannot access the source must say so; source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. Says exact-name dispatch was attempted and rejected; does not claim pre-dispatch blocking.
- B2. Blocks further work and leaves workflow/task progress at its current point.
- B3. Preserves the original error reason verbatim: `model provider not enabled for vendor/model-zeta (request id req-731)`.
- B4. Offers a concrete correction/resume hint (enable/configure that exact model, then retry after user correction).
- B5. No fallback, substitution, or alternate lane/model dispatch.
- B6. Grounds its decision in the plugin reference it actually read, identifying the relevant section and accurately stating its rule; merely repeating the scenario or an unsupported recollection is insufficient.
- B6. Grounds its decision in the plugin reference it actually read, identifying the relevant section and accurately stating its rule; merely repeating the scenario or an unsupported recollection is insufficient.

## Gate-violation rule

Any proposed retry on another model/lane, silent substitution, or omission of the rejection reason fails.

## Layer 2 — Quality

Only if all behavior items pass, score Q1 (0–2): clarity and accurate progress reporting; Q2 (0–2): concrete next step without adding unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List each B-item as Y/N with a short quoted evidence phrase, then Q1/Q2. Treat a claimed but unsubstantiated source read as N for B6. PASS requires all B-items.
