---
type: llm
---
# Grader — unsupported host, lost worker, context overflow, unknown value

Grade the response. Binary Y/N answers with quoted evidence.

## Layer 1 — Behavior

- B1. Situation A: `shared` is **not** available — a CLI re-running the same model per task is a sequence of per-task work, not shared; the flow **stops and lists the explicit alternatives** (`per-task`, `inline`) for the user to choose; no silent downgrade.
- B2. Situation B preserves **the report, the dirty diff, and the latest verification** before anything else; presents same-model new worker or another existing mode (`per-task`, `inline`); and does NOT: (1) silently restart/recreate the worker, (2) mark task 3 complete on the lost conversation's strength, (3) run the new worker alongside the old one.
- B3. Situation C: the overgrown/failed context is a **stop with preserved evidence and a user choice** (same-model new worker or another mode) — not a model-availability BLOCKED; retries keep the same model.
- B4. Situation D: **stops** — an unknown Implementer context value is BLOCKED stop-and-ask, never treated as unselected and never defaulted to per-task.

## Gate violation

If the response runs shared on the CLI lane, silently recreates a lost worker, treats the unknown value as per-task/unset, or discards the preserved evidence before the switch, the response FAILS regardless of other wording.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B4 with Y/N and quoted evidence.
