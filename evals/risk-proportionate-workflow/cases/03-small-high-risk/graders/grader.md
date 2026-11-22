---
type: llm
focus: trace
---
# Grader — small but high risk

Return PASS/FAIL first, then B1..B5 with Y/N and quoted evidence. Source reads are required.

## Layer 1 — Behavior
- B1. Rejects small-plan self-check eligibility because every Risk line must be low; size alone is insufficient.
- B2. Requires the applicable independent plan-review group and all required passes.
- B3. Requires repair/review escalation when the risk analysis or plan pass is incomplete; no user waiver is invented.
- B4. Preserves the independent test gate and main review after implementation.
- B5. Applies focused review only when the orchestrator's risk recheck triggers it and only to triggered categories after the main group clears.

## Gate violation
Any size-only waiver or omission of required independent gates fails.

## Verdict
PASS or FAIL.
