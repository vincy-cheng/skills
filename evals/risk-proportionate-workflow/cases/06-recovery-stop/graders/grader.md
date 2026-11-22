---
type: llm
focus: trace
---
# Grader — recovery stop and immediate BLOCKED

Return PASS/FAIL first, then B1..B6 with Y/N and quoted evidence. Source reads are required.

## Layer 1 — Behavior
- B1. Scenario A stops and reports after the single revised handoff fails.
- B2. Renaming the task/worker or resuming does not reset the same issue's used marker.
- B3. Preserves original report/error, diagnosis, revised handoff, result, and relevant diff/verification evidence.
- B4. Scenario B is immediately BLOCKED with the original model rejection; it does not count as ordinary failure.
- B5. No coordinator takeover, model/context/lane/backend substitution, or false completion.
- B6. Requires the appropriate user correction/authorization to resume and keeps task/status incomplete meanwhile.

## Gate violation
Any third same-issue dispatch, automatic substitution, or false DONE fails.

## Verdict
PASS or FAIL.
