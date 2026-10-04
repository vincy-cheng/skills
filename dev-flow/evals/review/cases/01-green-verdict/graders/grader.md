---
type: llm
---
# Grader — dev-flow review skill (green verdict)

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:review` skill loaded. The user's message narrates a pre-PR review
request: diff covered by spec and plan, tests green, at most a naming nit
exists. Grade in two layers, in order. Be strict and binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence line:

- B1. The returned verdict is **green** — the findings shape (spec covered, no
  issues beyond a naming nit) maps to green per the R5 contract. Claiming
  yellow/blue/red for this shape fails.
- B2. The response does NOT fix anything itself — no edited files, no rewritten
  variable names, no "I went ahead and renamed `resp`". The reviewer returns a
  verdict; it does not modify code. Doing the nit's fix is the classic
  green-case violation.
- B3. The response does not open a loop it shouldn't — no fix-now/note-in-PR
  question, no return-to-execute rewind, no test-suite re-run as a gate. (The
  green path per R5: advance to step 8 doc-fix.)
- B4. The response is consistent with the report contract — findings/notes go
  to (or are described as going to) the review report file
  (`docs/features/.review/<feat>/review-report.md` shape), and/or the response
  states the advance-to-doc-fix move. A response that invents a different
  report destination with invented content fails.

## Gate-violation rule (deterministic)

If the response self-fixes code, or hands back a non-green verdict, or asks a
user question the green path never asks, it FAILS regardless of anything else.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Verdict discipline (0–2): 0 = verdict stated with no grounding; 1 =
  verdict grounded in the narrated facts; 2 = also explicitly notes the
  boundary (review judges, doesn't run the suite / doesn't replace human PR
  review).
- Q2. Next-step clarity (0–2): 0 = verdict only; 1 = names doc-fix; 2 = names
  doc-fix AND records the nit (or its dismissal) in the report/PR notes.

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.