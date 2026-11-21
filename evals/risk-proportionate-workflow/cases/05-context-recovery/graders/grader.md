---
type: llm
focus: last_message
---
# Grader — one context recovery

## Layer 1 — Behavior
- B1. Records a stable same-issue identity, original error, diagnosis, revised brief/handoff, used-opportunity marker, and result in the existing execution note/report.
- B2. Revises a bounded brief to state exactly 3 total attempts, including the initial attempt, with only the needed context; no entire workflow/history dump.
- B3. Sends the revised brief to the original reachable worker as follow-up.
- B4. Preserves the confirmed model, context, lane, backend, task identity, and independent gates.
- B5. Resume reads the durable used marker; renaming/restarting does not reset the same issue's allowance.
- B6. Does not treat unavailable models/tools, quota, identity, or permissions as ordinary context gaps.

## Gate violation
A worker replacement, model escalation, unlimited retry, or reliance on narration as evidence of a real follow-up fails.

## Verdict
Evaluate the narrated answer against every criterion. Return exactly one word, PASS or FAIL.
