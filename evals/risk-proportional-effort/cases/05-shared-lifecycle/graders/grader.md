---
type: llm
---
# Grader — shared worker follow-up with live drift

Grade the response. Binary Y/N answers with quoted evidence.

## Layer 1 — Behavior

- B1. The dispatch does **not** proceed as-is for (b): the dirty file overlapping task 3 must be resolved first (inspect/attribute; never attribute dirty code to the run's HEAD).
- B2. For (c), **live code wins over the plan text**: the follow-up brief carries the actual symbol from HEAD (the plan was wrong; correct it), not the stale plan name — no treating the orchestrator's memory of the plan as live evidence.
- B3. The follow-up brief carries the delta (task 3's text + the changed/confirmable pieces) and does **not** re-send unchanged already-delivered shared guidance; guidance whose delivery can't be confirmed is reloaded, not assumed.
- B4. After the report: the **coordinator** does the task check (scope/integration/verification), commit goes through `dev-flow:commit`, and the shared conversation **does not replace** the independent test gate (step 6) or main review (step 7).

## Gate violation

If the response dispatches over the dirty overlapping file, trusts the plan's stale symbol over live HEAD, re-sends all prior guidance wholesale, or claims shared context covers the independent gates, the response FAILS regardless of other wording.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B4 with Y/N and quoted evidence.
