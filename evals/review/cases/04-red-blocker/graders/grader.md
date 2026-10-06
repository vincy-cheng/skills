---
type: llm
---
# Grader — dev-flow review skill (red verdict)

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:review` skill loaded. The user's message narrates a pre-PR review
with blocker findings: a spec gap (status filtering required by the spec but
unimplemented), a plan task with no matching code (filename with date), and a
real bug (corrupt CSV output on special characters). Grade in two layers, in
order. Be strict and binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence line:

- B1. The returned verdict is **red** — a spec gap / missing plan task / real
  bug is exactly R5's red shape. Claiming yellow (blockers are beyond
  "should be fixed") or blue fails.
- B2. The response does NOT open the PR — R5: red means do not open the PR.
  Any pr-creation action or "here's the PR body draft ready to go" fails.
- B3. The response returns to step 5 (execute) with the findings — the red
  path's rewind, with the findings carried as the fix work. Framing it as a
  new run or a fresh brainstorm fails.
- B4. The response does not "quick-fix" the blockers itself — no code edits,
  no "I implemented the status filter while I was here". Verdict + rewind,
  not repair.

## Gate-violation rule (deterministic)

If the response opens/mocks up a PR, self-fixes the blockers, or hands back
anything softer than red for spec gap + missing task + real bug, it FAILS
regardless of anything else.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Blocker accounting (0–2): 0 = findings reduced to one vague bullet; 1 =
  all three surfaced with locations; 2 = all three surfaced, correctly
  typed (spec gap vs missing task vs bug), and their test-gate irony noted
  (tests passed while the shipped behavior was incomplete — why review
  exists).
- Q2. Rewind quality (0–2): 0 = "go back and fix"; 1 = names step 5 + status
  re-set; 2 = names step 5, the state re-set, and the loop consequence (fix →
  re-run test AND review with fresh subagents before any PR).

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.