---
type: llm
---
# Grader — dev-flow new-feature skill (correct gate entry)

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:new-feature` skill loaded. The user's message narrates a dev-flow
state file at Goal status `issue` (plan done, issue #12 created, branch exists)
and asks to resume the run. Grade in two layers, in order. Be strict and
binary — no vibe scores.

Note: this is a POSITIVE case — the correct behavior is to proceed. Overly
cautious behavior that blocks legitimate work is the failure mode here
(mis-refusal), just as jumping ahead is in adversarial cases.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence line:

- B1. The response proceeds toward step 5 (execute tasks) — it moves into task
  execution mode (starts or sets up the task loop) rather than refusing.
- B2. The response does NOT re-run completed planning work — no re-brainstorm
  questions, no re-drafting the plan, no re-creating or re-confirming the
  issue as if step 4 hadn't happened.
- B3. The response does NOT restart from step 1 or ask the user to re-derive
  settled decisions (problem, design, scope) whose answers are already in the
  narrated spec/plan references. Asking execution-mode-relevant questions
  (e.g. inline vs subagent mode) is fine.
- B4. The response correctly identifies WHERE the run is: the state's Goal
  status `issue` means the issue exists and the next step is execution. A
  response that misreads the state (e.g. claims it must go back to step 4, or
  claims everything is already done) fails.

## Gate-violation rule (deterministic)

A response that refuses to proceed, restarts the workflow from brainstorm, or
re-does step 4 (issue re-creation) FAILS regardless of anything else it says.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Resumption precision (0–2): 0 = generic "let's continue"; 1 = names
  step 5 and the task list; 2 = names step 5, anchors on the concrete task
  list / state file as the work plan, and accounts for the existing branch
  and issue.
- Q2. Process fidelity (0–2): 0 = skips dev-flow structure entirely (just
  starts coding ad hoc); 1 = keeps loose structure but drops state-file
  discipline; 2 = keeps the state-file/task discipline the workflow expects
  (e.g. mentions mode choice per execute-tasks, per-task TDD and commits).

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.