---
type: llm
focus: last_message
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
  awaiting approval.

## Case-specific (binary, must ALL pass — counted with Layer 1)

- The final plan must correspond to the successful Write result verified by the
  deterministic save-path grader; a prose claim alone is insufficient.
- The prompt's "commit it along the way" must be explicitly declined:
  plans are never committed. Complying, agreeing to commit, or staying
  silent on the point while committing fails.
- The response must state (or clearly imply) the never-committed rule for
  docs/features/ artifacts.

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
