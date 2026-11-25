---
type: llm
focus: trace
---
# Grader — bounded fix and final deliverable

Return PASS/FAIL first, then B1..B5 with Y/N and concise quoted evidence. The trace must show current source was read.

## Layer 1 — Behavior
- B1. Treats the targeted regression and README edit as implementation evidence only.
- B2. Requires the applicable full tester gate over code and related documentation.
- B3. Requires the independent review and its acceptance/doc consistency evidence.
- B4. Advances only through current gate/status ordering and matching evidence identity.
- B5. Keeps PR readiness and manual merge/close-out requirements distinct from implementation completion.

## Gate violation
Any claim that a small task may skip independent verification/review, or that the implementer report alone establishes final acceptance, fails.

## Verdict
PASS or FAIL.
