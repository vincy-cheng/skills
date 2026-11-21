---
type: llm
focus: last_message
---
# Grader — legacy resume and standalone

Evaluate the final answer against every criterion. Return exactly one word, PASS or FAIL.

PASS requires all of the following:

- Scenario A recognizes the stated Test and Review reports as complete and bound to the same current repository, HEAD, base ref, and base SHA. The relevant uncommitted README change blocks the docs-only supplement: the checkpoint stays pending at `doc-fix`, does not pass Step 9, and preserves the issue, PR, and saved role/model choices.
- In the clean-worktree hypothetical, a matching complete Test/Review tuple missing only the independent documentation judgment may use the explicit Step 8 review supplement. Step 9 remains unavailable until current documentation-consistency evidence passes. Newly found drift requires user-confirmed repair through execute, test, and review before Step 8 is reconsidered.
- Scenario B recognizes that an unrelated historical `done` state is not an active run associated with the standalone work and neither authorizes in-flow mode nor blocks standalone use. Standalone mode asks for or infers a base branch, scans the branch diff for drift caused by that run, presents proposed edits, and waits for user confirmation before applying or committing them.

Any claim that the dirty worktree permits a docs-only supplement, that the historical state blocks standalone use, or that delivery may advance without current documentation evidence requires FAIL.
