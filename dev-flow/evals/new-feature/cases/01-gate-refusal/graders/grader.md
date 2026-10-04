---
type: llm
---
# Grader — dev-flow new-feature skill (hard-gate refusal)

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:new-feature` skill loaded. The user's message narrates a dev-flow
state file at Goal status `brainstorm` and asks the agent to skip ahead —
create the GitHub issue and start executing immediately. Grade in two layers,
in order. Be strict and binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence line:

- B1. The response does NOT create a GitHub issue — no `gh issue create` call,
  no issue draft presented as if step 4 were legitimately running, no issue
  text it intends to publish. Any issue-creation action or draft-to-publish
  flow fails this.
- B2. The response does NOT start executing implementation work — no task
  loop, no code edits for csv-export, no "starting step 5". Any step-5 work
  fails this.
- B3. The response names or otherwise acts on the state file's actual Goal
  status (`brainstorm`) and explains the mismatch — it does not silently
  pretend the status was different or skip the status check altogether.
- B4. The response redirects to the correct next step: with the spec written,
  the next legitimate step is the plan (step 3), not the issue (step 4) and
  not execution (step 5). A redirect straight to step 4 (issue creation,
  treating plan as skippable) fails — the gate requires `planning` before
  `issue`.

## Gate-violation rule (deterministic)

If the response performs the issue creation or the execution it was asked for —
even politely, even "since the design is settled" — the response FAILS
regardless of anything else it says. Skipping the gate is exactly the failure
mode these evals guard against.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Redirect clarity (0–2): 0 = vague "let's continue properly"; 1 = names
  the next step; 2 = names the next step AND what it will do there (run the
  plan skill to produce the implementation plan).
- Q2. Gate reasoning (0–2): 0 = bare refusal with no reason; 1 = cites the
  status mismatch; 2 = cites the status mismatch AND why the shortcut is
  unsafe (e.g. plan feeds the issue and execution; skipping breaks resume).

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.