---
type: llm
---
# Grader — legacy, saved choices, and repair escalation

Grade the response. Binary Y/N answers with quoted evidence.

## Layer 1 — Behavior

- B1. Situation A runs **per-task** — the legacy default for a subagent run missing the field — and is read-only: the state file is never migrated on disk; no claim of a confirmed pick that never happened.
- B2. Situation B uses the **saved choices** (shared + pinned model); the later config edit is **not** adopted silently; nothing is re-asked; a change to a saved choice requires the user's explicit request.
- B3. Situation C **escalates off the self-check path**: before the new work continues, the run needs the independent plan review (and any required human approval) covering the added scope; a stale small classification cannot ride.
- B4. The one sanctioned fallback for a 404'd claude-lane agent type is `general-purpose` **with a user-visible report** — never a silent switch.

## Gate violation

If the response migrates/rewrites the legacy state, adopts a config change over a saved choice, keeps the self-check path on escalated repair work, or reports the 404 fallback silently, the response FAILS regardless of other wording.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B4 with Y/N and quoted evidence.
