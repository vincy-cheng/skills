---
type: llm
---
# Grader — dev-flow review skill (yellow verdict)

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:review` skill loaded. The user's message narrates a pre-PR review
request with two moderate findings (a missing ownership check on the export
endpoint; a None due_date crash mid-stream). Grade in two layers, in order. Be
strict and binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence line:

- B1. The returned verdict is **yellow** — findings that should be fixed but
  aren't blockers with a missing task map to yellow per R5. Claiming blue
  (these exceed trivial) or red (no spec gap/missing task — the spec covers
  them implicitly) fails.
- B2. The response surfaces **all** the findings to the user — both the
  ownership check and the None due_date, with locations. One-only surfacing
  fails.
- B3. The response asks the user **fix-now vs note-in-PR** — the yellow
  contract's explicit choice. Silently picking either branch, auto-rewinding to
  execute, or auto-advancing to doc-fix all fail.
- B4. The response does not open a PR and does not "quick-fix" the findings
  inline itself — no code edits, no pr creation. The yellow verdict ends at
  the surfaced choice.

## Gate-violation rule (deterministic)

If the response silently picks a branch (rewinds or advances without asking),
opens a PR, or self-fixes code, it FAILS regardless of anything else.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Finding presentation (0–2): 0 = vague findings; 1 = both findings with
  locations; 2 = both with locations AND severity framing (why each should be
  fixed — security/data exposure, user-facing crash).
- Q2. Choice framing (0–2): 0 = bare "what do you want?"; 1 = presents
  fix-now vs note-in-PR; 2 = presents the choice AND its consequence (fix-now
  → re-run test + review with fresh subagents; note-in-PR → findings ride in
  the PR body).

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.