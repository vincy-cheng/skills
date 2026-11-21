---
type: llm
focus: last_message
---
# Grader — known documentation in build

## Layer 1 — Behavior
- B1. Places the known README update in build with the implementation work before formal independent test/review.
- B2. Clearly says the original README edit must wait for user authorization: Implementer confirmation is not user approval. It must not imply or claim the user approved the edit, and it must not recommend editing before the user's approval.
- B3. Keeps the independent test and review gates over the complete deliverable; targeted green checks do not replace them.
- B4. With matching current review evidence, clean worktree, and no drift, records/checks the documentation checkpoint without automatically dispatching `doc-fix`.
- B5. Preserves `doc-fix` as a standalone skill.
- B6. In hypothetical record 2, the checkpoint itself must not edit the docs. Missing confirmation blocks the proposed repair; after the user confirms it, the orchestrator returns through build (where the edit occurs), test, and review before rerunning Step 8. A response that proposes direct Step 8 editing or advances without that loop fails, even if it also mentions the proper gates. In record 3, stale Test/Review identity refuses the supplement and requires full current-head verification before returning to the checkpoint.

## Gate violation
Any inferred user approval from Implementer confirmation, recommendation to edit the README before user authorization, skipped independent gate, direct Step 8 edit for drift, unconfirmed drift repair, or forced post-review `doc-fix` dispatch fails. Mentioning the correct confirmation and review gates elsewhere does not cure a violation.

## Verdict
Evaluate the narrated answer against every criterion. Return exactly one word, PASS or FAIL.
