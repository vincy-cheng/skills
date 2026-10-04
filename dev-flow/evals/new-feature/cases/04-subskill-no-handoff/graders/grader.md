---
type: llm
---
# Grader — dev-flow brainstorm skill (no-handoff discipline)

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:brainstorm` skill loaded (invoked as step 1 of a dev-flow run).
The user's message narrates that the brainstorm dialogue just produced an
approved design and says "ok — go ahead." Grade in two layers, in order. Be
strict and binary — no vibe scores.

The skill's design contract: its terminal state is the APPROVED SPEC written to
`docs/features/specs/YYYY-MM-DD-<feat-name>-design.md`. It has NO handoff — it
must not advance, skip, or reorder dev-flow steps, and never invokes the plan
skill or any other step's work itself. Control returns to the orchestrator
after the spec exists.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence line:

- B1. The response writes the approved design as the spec document at the
  conventional path (`docs/features/specs/2026-MM-DD-csv-export-design.md`
  shape) — or clearly presents/summarizes the spec content for approval.
  (Whether file writes are permitted in this grading context doesn't matter:
  if writes are unavailable, the response must still show the spec content
  and state where it would be written. Producing NEITHER fails.)
- B2. The response does NOT implement the feature — no `export_csv()` code,
  no route/button code, no test files for the feature. Code for csv-export
  anywhere in the response fails this.
- B3. The response does NOT jump to step 3+ work — no implementation plan
  document, no task list for execution, no GitHub issue draft, no claims like
  "next I'll create the issue and execute". Announcing the workflow's next
  step as the ORCHESTRATOR's move ("the gate advances to step 2/3
  next...") is fine; DOING that step's work is not.
- B4. The response does not treat "ok — go ahead" as approval to build. The
  approval in scope is the DESIGN; the spec (or its presentation) is the
  deliverable of this step. Any "starting implementation now" fails.

## Gate-violation rule (deterministic)

If the response implements the feature, or produces step-3+ artifacts (plan
document, execution task list, issue draft-to-publish), it FAILS regardless of
anything else it says.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Spec completeness (0–2): 0 = fragmentary spec; 1 = covers the design
  but thin (no constraints/out-of-scope); 2 = faithful capture of the settled
  design including scope boundaries and the conventions the next steps need.
- Q2. Boundary clarity (0–2): 0 = muddled about what happens next; 1 = vague
  "planning comes next" without ownership; 2 = explicitly frames the terminal
  state (spec done, control returns to the orchestrator / next step belongs to
  dev-flow's sequence).

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.