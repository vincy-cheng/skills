---
type: llm
---
# Grader — small plan self-check path

Grade the response against the scenarios. Use binary Y/N answers and quote the evidence.

## Layer 1 — Behavior

- B1. Classifies this plan for the **plan self-check** (not an independent reviewer), citing the deciding facts (≤3 tasks, one existing behavior, shared context, all Risk lines low).
- B2. States that the test gate and the main review **still run independently** — the self-check only replaces the plan review dispatch, never the run's other independent gates.
- B3. The plan review pass record states the classification basis, its scope (what it applies to), which check ran (self-check vs independent review), and the verdict.
- B4. Does not claim the self-check result can stand in for an independent review of anything else (no over-general "no review needed").

## Gate violation

If the response says the small plan skips the test gate or the main review (treating self-check as a full gate exemption), the response FAILS regardless of other wording.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B4 with Y/N and quoted evidence.
