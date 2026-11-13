---
type: llm
---
Grade the created Traditional Chinese memo against the narrated acceptance record. Do not reward a short summary that drops formal requirements.

## Layer 1 — Behavior (all required)

- B1. Opens with the conditional acceptance decision and states pilot entry is allowed only after backup restoration is demonstrated.
- B2. Preserves all three acceptance criteria: 12 required scenarios pass; zero unresolved severity-1/2 defects; approval audit records actor, timestamp, and outcome.
- B3. Retains traceable evidence identifiers and results: R-204 (12/12), D-18 (zero open severity-1/2), A-09 (30 samples with all three fields).
- B4. Uses natural, formal Traditional Chinese suited to a review committee, without changing the decision or inventing claims.
- B5. Actually creates `acceptance-memo.md` or clearly reports a tool failure instead of claiming a save that did not happen.
- B6. The tool trace shows the plugin-root `references/output-style.md` was read before drafting; the response does not merely claim it was read.

## Layer 2 — Quality (only if all B-items pass)

- Q1. Information order (0–2): decision and condition are immediately clear.
- Q2. Formal readability (0–2): concise sentences and useful organization while retaining the memo's purpose and evidence.

## Negative checks

Poor output samples (each must fail):

- Long preamble: “本備忘錄旨在說明本次審查的背景、流程及相關注意事項……” followed by the decision only at the end. It fails B1.
- Missing evidence: “建議有條件接受，完成備份還原後可進入試點。測試大致通過。” It omits the criteria and traceable evidence; it fails B2/B3.
- Summary-only formal output: “本服務獲有條件接受，完成備份還原後可進入試點。” It drops every criterion and evidence item; it fails B2/B3.

## Verdict

First line `PASS` or `FAIL`. List B1..B6 as Y/N with evidence and Q1/Q2. PASS requires every B-item.
