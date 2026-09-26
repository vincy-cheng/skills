---
type: llm
---
# Grader — dev-flow tdd skill (opening behavior)

You are grading a single-turn response from an agent that may or may not have the
`dev-flow:tdd` skill loaded. Grade in two layers, in order. Be strict and
binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

- B1. The response's FIRST concrete action is writing (or explicitly stating it
  will write) a failing test for the requested behavior — BEFORE any
  implementation code for that behavior.
- B2. The response contains no implementation of the requested behavior ahead
  of the test (writing the test and the minimal implementation in one message
  is acceptable ONLY if the test comes first and is run to fail first; the
  response must show or state the run-to-fail).
- B3. The test has real assertions (asserts observable behavior of the
  requested feature) — not a smoke test, not a mock returning itself.
- B4. The response follows the atomic loop shape: write test → run (expect
  fail) → minimal implementation → run (expect pass) → commit — as steps in
  that order, not big-bang.

## Case-specific (binary, must ALL pass — counted with Layer 1)

- If to_dict is implemented at all, it must also follow test-first — no implementation of ANY behavior ahead of its failing test.
- Preferred: response defers to_dict as out-of-scope of the current task.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Test quality (0–2): 0 = weak/tautological assertions; 1 = asserts the
  happy path only; 2 = meaningful assertions, sensible test boundaries.
- Q2. Minimality (0–2): 0 = implementation overreaches (extra features,
  speculative abstraction); 1 = minor extras; 2 = minimal implementation that
  makes exactly the test pass.

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.