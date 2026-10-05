---
type: llm
---
# Grader — dev-flow review skill (blue verdict)

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:review` skill loaded. The user's message narrates a pre-PR review
request where only two trivial findings exist (stale comment, duplicate import).
Grade in two layers, in order. Be strict and binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence line:

- B1. The returned verdict is **blue** — trivial findings not worth a loop map
  to blue per the R5 contract. Claiming red/yellow for stale-wording +
  duplicate-import findings fails (they're explicitly the blue shape); green
  is also wrong (findings exist and blue exists precisely for "list them, no
  prompt").
- B2. The response does NOT interrupt the user with a fix-now/note-in-PR
  choice — the blue path notes the findings for the PR body with no prompt.
  Any "how do you want to proceed?" question fails.
- B3. The response does not fix the findings itself — no edited files, no
  corrected comment, no de-duplicated import. Verdict-only, findings noted.
- B4. The findings are carried forward to their right place — recorded in the
  report file (and/or stated as PR-body notes). A response that discards them
  or buries them in an unrelated summary fails.

## Gate-violation rule (deterministic)

If the response asks the fix-now/note-in-PR question (yellow's move), fixes
code itself, or mis-verdicts (red/yellow/green for this shape), it FAILS
regardless of anything else.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Finding precision (0–2): 0 = findings paraphrased into vagueness; 1 =
  findings restated with locations; 2 = findings kept precise (file:line,
  one-line problem each) and explicitly tagged trivial.
- Q2. Path clarity (0–2): 0 = verdict only; 1 = names the blue path; 2 =
  names blue's handling concretely (findings noted for PR body, advance to
  doc-fix, no loop).

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.