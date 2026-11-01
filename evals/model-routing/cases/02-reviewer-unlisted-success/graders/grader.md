---
type: llm
---
# Grader — Reviewer: exact model is accepted though absent from examples

Grade against the plugin-owned `references/model-routing.md`, which the prompt requires the agent to load through the relevant dev-flow skill. The scenario is narrated evidence, not a transcript of hidden tool calls. Be strict and binary. A response that cannot access the source must say so; source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. Correctly chooses successful dispatch and does not claim BLOCKED.
- B2. Names the exact model `vendor/model-zeta` as the dispatch pin; for this implementer case, honors the saved choice despite changed config.
- B3. Specifies fresh isolated context with `fork_turns: "none"`.
- B4. Explains the displayed examples do not restrict availability because there is no enforced enum, and attempts exact name unchanged.
- B5. No fallback, substitution, or claim that example-list omission blocks dispatch.
- B6. Grounds its decision in the plugin reference it actually read, identifying the relevant section and accurately stating its rule; merely repeating the scenario or an unsupported recollection is insufficient.
- B7. Reports completion without inventing extra tool details.

## Gate-violation rule

Any BLOCKED decision based only on example-list omission, different model/backend/lane, or missing isolated context fails.

## Layer 2 — Quality

Only if all behavior items pass, score Q1 (0–2): clarity and accurate progress reporting; Q2 (0–2): concrete next step without adding unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List each B-item as Y/N with a short quoted evidence phrase, then Q1/Q2. Treat a claimed but unsubstantiated source read as N for B6. PASS requires all B-items.
