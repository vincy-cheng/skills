---
type: llm
focus: last_message
---
# Grader — legacy resume and standalone

Evaluate the final answer against every criterion. Return exactly one word, PASS or FAIL.

PASS requires all of the following:

- A1 recognizes the stated Test and Review reports as complete and bound to the same current repository, HEAD, base ref, and base SHA. The relevant uncommitted README change blocks the docs-only supplement: the checkpoint stays pending at `doc-fix`, does not pass Step 9, and preserves the issue, PR, and saved role/model choices.
- A2 selects the explicit Step 8 documentation-evidence supplement through `dev-flow:review` for a matching complete Test/Review tuple, a clean worktree, and only the missing documentation judgment. Step 9 remains unavailable until current documentation-consistency evidence passes. Newly found drift requires user-confirmed repair through execute, test, and review before Step 8 is reconsidered.
- Scenario B recognizes that an unrelated historical `done` state is not an active run associated with the standalone work and neither authorizes in-flow mode nor blocks standalone use. Standalone mode asks for or infers a base branch, scans the branch diff for drift caused by that run, presents proposed edits, and waits for user confirmation before applying or committing them.

Any conflicting instruction for the same scenario decision requires FAIL, even if the answer also states the correct rule elsewhere. In A2's missing-judgment-only path, invoking `dev-flow:doc-fix`, using Step 10 to supplement the judgment, updating or publishing the PR before the supplement result, or skipping Step 9's current evidence gate requires FAIL. A separate conditional explanation that newly found drift follows the confirmed build-repair path is correct. Any claim that A1's dirty worktree permits a supplement, that the historical state blocks standalone use, or that delivery may advance without current documentation evidence also requires FAIL.
