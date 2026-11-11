---
type: llm
---
# Grader — Codex per-step counts, precedence, concurrency, and legacy fallback

Grade against the plugin-owned routing reference and directly relevant skill contract, which the prompt requires the agent to read. Narrated fixture evidence is not hidden execution. Be strict and binary. Source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. Codex uses codex_reviewers and ignores the malformed inactive reviewers map; red_team has 2, plan_review 1, focused_review 3; focused_review takes precedence over the legacy model; main_review falls back to legacy/default, then session default if absent. Dispatch max 2 concurrently and queue the third; do not shrink count. Every reviewer gets fresh context, identical frozen inputs, and unique report destination. All narrated reports pass, so all configured groups clear.
- B2. Correctly reports the workflow state and next action for each subcase.
- B3. Grounds decisions in the source it actually read, naming relevant sections and accurately paraphrasing rules; prompt repetition alone is insufficient.

## Gate-violation rule

Any interpretation of inactive Claude config, loss of count, shared report path, or use of the legacy model for configured steps fails.

## Layer 2 — Quality

Only if every B-item passes, score Q1 (0–2): clarity and complete case coverage; Q2 (0–2): concise, actionable progress reporting without unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List every B-item Y/N with short quoted response evidence, then Q1/Q2. Treat an unsubstantiated source-read claim as N for B3. PASS requires all B-items.
