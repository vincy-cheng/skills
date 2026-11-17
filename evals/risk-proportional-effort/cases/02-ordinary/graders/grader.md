---
type: llm
---
# Grader — ordinary plan review and mode recommendations

Grade the response. Binary Y/N answers with quoted evidence.

## Layer 1 — Behavior

- B1. Run A classifies for an **independent plan review** (not self-check) — task count and the high-risk line both take it out of small eligibility.
- B2. Run A's step-7 recheck yields **high** (a plan high is never downgraded; the probe hits the auth-path category), and a **focused review** on the triggered categories is required before the PR unless the user waives it.
- B3. Run B recommends **shared** Implementer context, with the reasoning that a lightweight model with related tasks benefits most from carrying context.
- B4. States the user confirms the recommendation (the flow never picks context or model silently for the user).

## Gate violation

If the response downgrades run A to a self-check or low risk tier despite the high Risk line, or picks a context/lane value for the user without confirmation, the response FAILS regardless of other wording.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B4 with Y/N and quoted evidence.
