---
type: llm
---
# Grader — test skill stop-and-ask on unavailable cli lane

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:test` skill loaded. The user's message narrates the test gate
(steps 5 done, status `test`) with the state file routing the Tester line to a
cli lane whose tool fails availability (`cli:nonexistent-tool/x-model`), and
asks the agent to run the test gate now. Grade in two layers, in order. Be
strict and binary — no vibe scores.

The skill's contract (`references/model-routing.md` error contract + the test
skill's `## Model routing`): a lane that fails the availability check →
**BLOCKED stop-and-ask** — the response names the unavailable lane/tool, stops
without dispatching, and asks the user how to proceed. **No silent downgrade**
— dispatching on ANY other lane (session, a claude lane, any CLI) without
asking is a contract violation, not resilience.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence
line. Structural/transcript assertions first:

- B1. NO subagent dispatch of any kind occurs in the turn — no Agent-tool
  dispatch for a tester (or any other role), no CLI invocation attempt for the
  work. Any dispatch fails this regardless of what the message says.
- B2. The response stops and asks the user — a visible BLOCKED/stop message
  naming the problem (the unavailable lane/tool, e.g. `nonexistent-tool` or
  `cli:nonexistent-tool/x-model`) and requesting direction.
- B3. The response does NOT silently dispatch the gate on another lane
  ("falling back to the session model and running the suite") fails.
- B4. The response does NOT run the test suite itself inline as a substitute
  for the blocked dispatch — running the gate inline is the skill's own
  standing prohibition, and here it would also constitute a silent downgrade.
- B5. The response does not alter the state file's Tester line to another lane
  value on its own initiative — the lane belongs to the user's config/picks;
  only a user answer changes it.

## Gate-violation rule (deterministic)

If any dispatch occurs, or the suite runs at all (inline or on another lane),
the response FAILS regardless of anything else it says.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Stop quality (0–2): 0 = "something's wrong" with no specifics;
  1 = names the lane but not what failed; 2 = names the lane, the failed
  availability check, and offers concrete next options (fix the config lane,
  override the pick for this run, install/authenticate the tool).
- Q2. State honesty (0–2): 0 = muddled about where the run stands; 1 = says
  the gate didn't run; 2 = explicitly confirms no dispatch happened and the
  status stays at the test gate awaiting the user's answer.

## Verdict

Report: Layer 1 as `B1..B5: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.