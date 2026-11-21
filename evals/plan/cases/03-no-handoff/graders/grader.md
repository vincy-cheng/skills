---
type: llm
---
You are grading a single-turn response from an agent that may or may not have the
`dev-flow:plan` skill loaded. Grade in two layers, in order. Be strict and
binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

- B1. The response's FIRST concrete action is producing (or explicitly stating
  it will produce) an implementation plan document — BEFORE any implementation
  code for the requested feature. A response that starts writing feature code
  fails immediately.
- B2. The plan contains the contract-complete mandatory sections: an overview
  referencing the spec/requirements, Global Constraints, a Flow Chart, a File
  Structure, and an ordered Tasks list.
- B3. Every task lists the files it creates/modifies (a Files block or
  equivalent), and the task list is copyable as `- [ ]` checkbox items.
- B4. The response performs no implementation and offers no "Execution
  Handoff" / next-skill invocation — its terminal state is the presented plan
  awaiting approval. Naming the applicable independent plan review as a
  prerequisite, without performing it or offering execution/handoff, is not an
  implementation handoff. Offering to start implementation or skip a required
  review or approval still fails.

## Case-specific (binary, must ALL pass — counted with Layer 1)

- The prompt explicitly asks to "get going on the first task right away" — the
  response must decline that push and present the plan awaiting approval
  instead. Complying (starting Task 1's implementation) fails immediately.
- The response must not invoke or promise to invoke any next skill
  (issue-drafting, execution, TDD) — even as an offer.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Task quality (0–2): 0 = tasks are vague wishes with no verification; 1 =
  tasks have verification but mix concerns; 2 = bite-sized, ordered,
  independently verifiable tasks with named verification per task.
- Q2. Contract fit (0–2): 0 = missing consumer needs (no acceptance fragments,
  no state-file-copyable list); 1 = partially addressed; 2 = issue material,
  verbatim task list, and coverage targets all derivable from the plan.

## Verdict

Evaluate the response against every Layer 1 and Layer 2 criterion. Return
exactly one word: `PASS` or `FAIL`. PASS only if all Layer 1 criteria pass;
otherwise return FAIL. Do not include evidence, scores, or any other text.
