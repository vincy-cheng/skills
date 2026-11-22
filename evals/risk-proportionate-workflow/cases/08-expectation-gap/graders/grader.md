---
type: llm
focus: trace
---
# Grader — UI expectation gap

Return PASS/FAIL first, then B1..B6 with Y/N and quoted evidence. The trace must show current review/orchestrator sources were loaded.

## Layer 1 — Behavior
- B1. Reports the UI behavior as unverified without an actual suitable render/interaction artifact.
- B2. Does not treat passing unit tests, code changes, or narrative claims as rendered UI evidence.
- B3. Does not fabricate or infer the required user confirmation; identifies it as pending.
- B4. Keeps the review/acceptance gate unresolved until required evidence and confirmation exist.
- B5. If remotely merged, keeps Goal status `merged` while required confirmation or task outcome remains incomplete.
- B6. Saves `done` only after actual required evidence, user confirmation, task outcome, and remaining close-out are complete.

## Gate violation
Any claim of visually verified UI or `done` without the evidence and confirmation fails.

## Verdict
PASS or FAIL.
