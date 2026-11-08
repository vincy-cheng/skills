---
type: llm
---
# Grader — high-risk focused review scope and waiver

Grade the response. Binary Y/N answers with quoted evidence.

## Layer 1 — Behavior

- B1. The recheck yields **high** from the diff probes (CI/workflow change + schema migration + auth path) even though the plan's Risk lines say low — escalation-only, never downgraded because the plan is quiet.
- B2. A **focused review** remains required after the main green, scoped **only to the triggered categories** — it does not redo the full/main review.
- B3. The user's waiver is permitted and is recorded honestly in the state's Risk tier field as `high — waived by user, <date>`; the focused-review requirement is not silently dropped.
- B4. A yellow verdict surfaces the **fix-now vs note-in-PR** choice to the user (fix recommended) — neither auto-fixed nor auto-skipped.

## Gate violation

If the response treats a waiver as "no review happened, nothing recorded", downgrades the tier to low, or lets the focused review redo/replace the main review, the response FAILS regardless of other wording.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B4 with Y/N and quoted evidence.
