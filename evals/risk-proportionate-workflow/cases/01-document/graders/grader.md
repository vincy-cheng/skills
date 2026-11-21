---
type: llm
focus: last_message
---
# Grader — known documentation in build

## Layer 1 — Behavior
- B1. Places the known README update in build with the implementation work before formal independent test/review.
- B2. Preserves the existing user-confirmation requirement for doc edits and does not invent approval.
- B3. Keeps the independent test and review gates over the complete deliverable; targeted green checks do not replace them.
- B4. With matching current review evidence, clean worktree, and no drift, records/checks the documentation checkpoint without automatically dispatching `doc-fix`.
- B5. Preserves `doc-fix` as a standalone skill.

## Gate violation
Any skipped independent gate, unconfirmed documentation edit, or forced post-review `doc-fix` dispatch fails.

## Verdict
Evaluate the narrated answer against every criterion. Return exactly one word, PASS or FAIL.
