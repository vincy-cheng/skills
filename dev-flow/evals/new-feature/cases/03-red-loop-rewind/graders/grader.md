---
type: llm
---
# Grader — dev-flow new-feature skill (red-loop rewind)

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:new-feature` skill loaded. The user's message narrates a dev-flow
run at Goal status `test` where the fresh tester subagent returned RED (3
concrete findings), and asks the orchestrator to handle the red verdict. Grade
in two layers, in order. Be strict and binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence line:

- B1. The response re-sets the state file's Goal status to `execute` (the
  red-loop rewind rule: a Verify-phase step sending work back means the
  orchestrator re-sets the status first, because step 5's gate requires
  incoming `issue` but treats `execute` as a valid fix-continue re-entry).
  Stating the intent to return to step 5 WITHOUT the status reset fails — the
  status reset is the mechanism, not decoration.
- B2. The response returns to step 5 with the findings as fix-continue work —
  it frames the fixes (streaming generator, content type, test-honesty item)
  as the work for re-entered execution, against the EXISTING task list on the
  EXISTING run.
- B3. The response does NOT restart the workflow — no new state file, no
  return to brainstorm/step 1, no fresh brainstorm of the feature, no
  "let's start over now that we know the design has issues". The design is
  fine; only the implementation is.
- B4. The response carries the findings FORWARD concretely — it names or
  preserves the specific red items (in-memory build, wrong content type,
  mocking-the-thing-under-test) as the fix list, rather than discarding them
  into a vague "fix the failures".

## Gate-violation rule (deterministic)

A response that restarts the whole flow (brainstorm anew, new run) or that
returns to step 5 without the status re-set FAILS regardless of anything else
it says.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Rewind correctness (0–2): 0 = rewind mechanism wrong or invented;
  1 = status reset + return to step 5 stated; 2 = also matches the existing
  tasks (fix-continue, no task-list rewrite) and notes re-running test (and
  review) with fresh subagents after the fixes.
- Q2. Findings handling (0–2): 0 = findings lost or paraphrased into
  nothing; 1 = findings carried as a list; 2 = findings prioritized sensibly
  (blockers first, honesty-note treated as a real fix item).

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.