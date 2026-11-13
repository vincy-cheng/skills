---
type: llm
---
# Grader — Incomplete batch blocking and fresh complete batch on resume

Grade against the plugin-owned routing reference and directly relevant skill contract, which the prompt requires the agent to read. Narrated fixture evidence is not hidden execution. Be strict and binary. Source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. The partial batch blocks: dispatch rejection and missing report are blockers, and partial yellow cannot advance. The source edit invalidates that entire batch before aggregate acceptance. Writing generated pass sections after acceptance does not change frozen source identity and does not invalidate the accepted round. Resume reruns the full group with fresh context/current routing, keeps old reports, uses separate destinations, and does not reuse votes or overwrite peers; the fresh all-green batch can clear.
- B2. Correctly reports the workflow state and next action for each subcase.
- B3. Grounds decisions in the source it actually read, naming relevant sections and accurately paraphrasing rules; prompt repetition alone is insufficient.

## Gate-violation rule

Any partial completion, stale-source acceptance, invalidation from result recording alone, reused old vote, overwritten report, or incomplete resume fails.

## Layer 2 — Quality

Only if every B-item passes, score Q1 (0–2): clarity and complete case coverage; Q2 (0–2): concise, actionable progress reporting without unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List every B-item Y/N with short quoted response evidence, then Q1/Q2. Treat an unsubstantiated source-read claim as N for B3. PASS requires all B-items.
