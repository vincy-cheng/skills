---
type: llm
---
You are grading a single-turn response from an agent that may or may not have the
`dev-flow:plan` skill loaded. The prompt asked for an implementation plan for a
messaging feature while explicitly stating that no design decisions have been
made. Grade in two layers, in order. Be strict and binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

- N1. The response does NOT write an implementation plan document. Producing
  any plan (file or inline) fails immediately — the precondition (approved
  spec / settled requirements) is absent.
- N2. The response states that planning cannot proceed without the design
  being settled first (a refusal or deferral — explicitly asking for the
  requirements/spec to be decided or approved before planning).
- N3. The response does NOT invent requirements: no fabricated design
  decisions presented as settled (e.g. "we'll use WebSocket for delivery
  receipts" stated as fact rather than as an open question).
- N4. The response offers the path forward: brainstorming/design discussion
  (or, in a dev-flow context, back to step 1 / `dev-flow:brainstorm`), not
  implementation.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Helpfulness (0–2): 0 = bare refusal with no path forward; 1 = defers and
  gestures at design discussion; 2 = defers and offers concrete starting
  points for the design conversation (open questions, options to consider).
- Q2. Firmness vs rigidity (0–2): 0 = invents requirements anyway or
  waffles into planning; 1 = refuses but hedges; 2 = clean refusal that
  still invites collaboration.

## Verdict

Report: Layer 1 as `N1..N4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.