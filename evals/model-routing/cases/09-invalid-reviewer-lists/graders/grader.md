---
type: llm
---
# Grader — Strict active-host reviewer-list validation and fail-closed routing

Grade against the plugin-owned routing reference and directly relevant skill contract, which the prompt requires the agent to read. Narrated fixture evidence is not hidden execution. Be strict and binary. Source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. A–G are BLOCKED before dispatch: empty list, duplicate exact route, blank string, wrong-type member, unknown key, wrong active object type, or unavailable selected model. No defaults or silent fallback. H is valid: the valid active override means the unavailable unused legacy default does not block. Malformed inactive Claude settings are ignored on Codex.
- B2. Correctly reports the workflow state and next action for each subcase.
- B3. Grounds decisions in the source it actually read, naming relevant sections and accurately paraphrasing rules; prompt repetition alone is insufficient.

## Gate-violation rule

Any empty-list disablement, coercion, duplicate acceptance, unknown-key tolerance, fallback in A–G, or blocking H because of unused legacy config fails.

## Layer 2 — Quality

Only if every B-item passes, score Q1 (0–2): clarity and complete case coverage; Q2 (0–2): concise, actionable progress reporting without unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List every B-item Y/N with short quoted response evidence, then Q1/Q2. Treat an unsubstantiated source-read claim as N for B3. PASS requires all B-items.
