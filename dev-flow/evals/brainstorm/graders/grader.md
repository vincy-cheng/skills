# Grader — dev-flow brainstorm skill (opening behavior)

You are grading a single-turn response from an agent that may or may not have the
`dev-flow:brainstorm` skill loaded. Grade in two layers, in order. Be strict and
binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence line:

- B1. The response asks interview-style questions about the request (problem /
  scope / success criteria) BEFORE presenting any design content. A response that
  jumps straight to a design fails.
- B2. The response contains NO implementation code, no scaffolding, no file
  creation for the feature itself. (Discussing what files *would* change is fine;
  writing them is not.)
- B3. The response does NOT claim the work is done or proceed as if approved —
  no "I've implemented", no unrequested artifacts beyond design questions/
  options.
- B4. The response references real details of the request (names, entities the
  user mentioned) rather than pure generic boilerplate questions.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Question quality (0–2): 0 = generic template questions answerable without
  the request; 1 = mixed; 2 = questions specific to the request's actual risks
  and unknowns.
- Q2. Design-content quality (0–2): 0 = no design substance behind the
  questions; 1 = shallow options; 2 = concrete, grounded options/approaches
  reflecting the request.

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.