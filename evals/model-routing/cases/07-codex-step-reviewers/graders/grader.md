---
type: llm
---
# Grader — Codex per-step counts, precedence, concurrency, and legacy fallback

Grade against the plugin-owned routing reference and directly relevant skill contract, which the prompt requires the agent to read. Narrated fixture evidence is not hidden execution. Be strict and binary. Source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. Codex uses codex_reviewers and ignores the malformed inactive reviewers map. Resolve all four keys and counts: red_team has 2 but is unrequested; plan_review has 1; focused_review has 3; absent main_review resolves to legacy/default (or session default if the legacy value is absent), but is unrequested. Only plan_review and focused_review dispatch and clear; do not trigger or claim clearance for red_team or main_review. The configured focused_review overrides legacy fallback. Dispatch max 2 concurrently and queue the third focused reviewer; do not shrink count. Every dispatched reviewer gets fresh context, identical frozen inputs, and a unique report destination.
- B2. Correctly reports the workflow state and next action for each subcase.
- B3. Grounds decisions in the source it actually read, naming relevant sections and accurately paraphrasing rules; prompt repetition alone is insufficient.

## Gate-violation rule

Any interpretation of inactive Claude config, loss of count, shared report path, use of the legacy model for configured steps, or dispatch/clearance of an unrequested group fails.

## Layer 2 — Quality

Only if every B-item passes, score Q1 (0–2): clarity and complete case coverage; Q2 (0–2): concise, actionable progress reporting without unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List every B-item Y/N with short quoted response evidence, then Q1/Q2. Treat an unsubstantiated source-read claim as N for B3. PASS requires all B-items.
