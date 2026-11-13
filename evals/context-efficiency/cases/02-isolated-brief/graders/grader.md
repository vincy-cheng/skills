---
type: llm
---
# Grader — isolated brief

Grade the produced dispatch brief. Answer each B-item with Y/N and quote the evidence.

## Layer 1 — Behavior

- B1. The brief contains the task.
- B2. The brief contains the constraints.
- B3. The brief contains the relevant paths.
- B4. The brief contains the exact interface from the earlier task.
- B5. The brief contains all of the supplied output-style contents.
- B6. The brief contains the report contract.
- B7. The brief excludes unrelated conversation history.
- B8. Each shared rule appears once in the brief.

## Gate violation

A missing required boundary item fails. Duplication of any supplied shared rule or copied unrelated conversation history fails.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B8 with Y/N and quoted evidence.
