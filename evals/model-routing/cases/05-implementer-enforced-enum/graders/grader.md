---
type: llm
---
# Grader — Implementer: authoritative enforced enum excludes requested model

Grade against the plugin-owned `references/model-routing.md`, which the prompt requires the agent to load through the relevant dev-flow skill. The scenario is narrated evidence, not a transcript of hidden tool calls. Be strict and binary. A response that cannot access the source must say so; source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. Stops BLOCKED before dispatch because an authoritative enforced enum excludes `vendor/model-zeta`.
- B2. Explicitly identifies the enforced enum values and the requested name’s exclusion.
- B3. Confirms no dispatch occurred and workflow/task progress remains in place.
- B4. Gives a correction/resume hint (choose an allowed exact model or change the authoritative tool restriction, then resume).
- B5. No fallback, substitution, or dispatch attempt.
- B6. Grounds its decision in the plugin reference it actually read, identifying the relevant section and accurately stating its rule; merely repeating the scenario or an unsupported recollection is insufficient.

## Gate-violation rule

Any dispatch attempt, alternate model/lane, or treating this enforced enum as merely illustrative fails.

## Layer 2 — Quality

Only if all behavior items pass, score Q1 (0–2): clarity and accurate progress reporting; Q2 (0–2): concrete next step without adding unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List each B-item as Y/N with a short quoted evidence phrase, then Q1/Q2. Treat a claimed but unsubstantiated source read as N for B6. PASS requires all B-items.
