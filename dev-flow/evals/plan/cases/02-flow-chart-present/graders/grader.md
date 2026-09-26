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
  awaiting approval.

## Case-specific (binary, must ALL pass — counted with Layer 1)

- The Flow Chart section must contain a real Mermaid `flowchart` (or
  equivalent) diagram with each task as a node labeled `Task N: <name>`,
  connected in execution order — a section header with no diagram fails.
- Every node must list the files that task touches (`Task N changes:
  file_a, file_b` or equivalent) — nodes without file lists fail.
- Nodes must match the Tasks section: every `Task N` heading has a matching
  chart node, and every file under a node appears in that task's Files block.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Task quality (0–2): 0 = tasks are vague wishes with no verification; 1 =
  tasks have verification but mix concerns; 2 = bite-sized, ordered,
  independently verifiable tasks with named verification per task.
- Q2. Contract fit (0–2): 0 = missing consumer needs (no acceptance fragments,
  no state-file-copyable list); 1 = partially addressed; 2 = issue material,
  verbatim task list, and coverage targets all derivable from the plan.

## Verdict

Report: Layer 1 as `B1..B4: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.