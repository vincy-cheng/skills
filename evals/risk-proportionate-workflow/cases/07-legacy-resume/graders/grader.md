---
type: llm
focus: trace
---
# Grader — legacy resume and standalone

Return PASS/FAIL first, then B1..B7 with Y/N and quoted evidence. The trace must show both requested skill sources.

## Layer 1 — Behavior
- B1. Does not accept a docs-only supplement over a relevant uncommitted README change or stale evidence.
- B2. Checks the existing report and current identity/worktree tuple before supplementing.
- B3. On a clean worktree with only the independent docs judgment missing, requests the permitted docs-only review supplement and records current evidence.
- B4. Requires new drift to return through confirmed build repair, test, and review.
- B5. Preserves the issue, PR, roles, model/context choices, and status lifecycle.
- B6. Does not advance to PR delivery without current documentation-consistency evidence.
- B7. Keeps `doc-fix` standalone and honors its standalone guided proposal/confirmation contract.

## Gate violation
Any bypass of the dirty-worktree/evidence checks, lost identity, or assumption that a legacy checkpoint passed fails.

## Verdict
PASS or FAIL.
