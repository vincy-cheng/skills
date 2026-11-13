---
type: llm
---
# Grader — Rerun the affected complete reviewer group after material changes

Grade against the plugin-owned routing reference and directly relevant skill contract, which the prompt requires the agent to read. Narrated fixture evidence is not hidden execution. Be strict and binary. Source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. A reruns the complete red_team group on revised design. B reruns the complete plan_review group after plan revision and cannot exceed the existing two-rework-round cap. C reruns every main reviewer on changed code. D BLUE fix-now rewinds to execute and blocks focused dispatch; after the later BLUE note-in-PR choice, the full focused group may run for high risk. E has no focused group because low risk does not trigger it. F follows the existing test-gate rewind after a code fix; preserve existing stage ordering.
- B2. Correctly reports the workflow state and next action for each subcase, including the two distinct BLUE choices and their sequencing.
- B3. Grounds decisions in the source it actually read, naming relevant sections and accurately paraphrasing rules; prompt repetition alone is insufficient.

## Gate-violation rule

Any member-only rerun, new stage, cap reset, low-risk focused dispatch, wrong ordering, or skipping the test rewind fails.

## Layer 2 — Quality

Only if every B-item passes, score Q1 (0–2): clarity and complete case coverage; Q2 (0–2): concise, actionable progress reporting without unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List every B-item Y/N with short quoted response evidence, then Q1/Q2. Treat an unsubstantiated source-read claim as N for B3. PASS requires all B-items.
