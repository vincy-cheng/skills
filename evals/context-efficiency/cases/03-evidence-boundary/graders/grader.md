---
type: llm
---
# Grader — evidence boundary

Grade the decision. Answer each B-item with Y/N and quote the evidence.

## Layer 1 — Behavior

- B1. The response does not allow targeted implementation evidence to replace the tester evidence required by step 6.
- B2. The response treats step 6 as the independent full-suite gate.
- B3. The response rejects cross-producer or cross-repository evidence reuse.
- B4. The response checks repository, HEAD SHA, base ref, base SHA, report path, and relevant working-tree state before reuse.
- B5. The response keeps targeted implementation checks separate from step 6.

## Gate violation

If the answer lets implementation evidence satisfy step 6, or ignores any required identity tuple item, the response FAILS.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B5 with Y/N and quoted evidence.
