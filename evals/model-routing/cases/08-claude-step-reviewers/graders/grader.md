---
type: llm
---
# Grader — Claude per-step lane overrides and read-only CLI report transport

Grade against the plugin-owned routing reference and directly relevant skill contract, which the prompt requires the agent to read. Narrated fixture evidence is not hidden execution. Be strict and binary. Source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. Claude uses reviewers and ignores malformed codex_reviewers. red_team has two configured routes; main_review has two. plan_review is absent, so it preserves the existing plan review route/source. Read-only CLI reviewers return complete reports through output; their drivers save verbatim without judging. Each concurrent member uses unique brief, captured-output, and report paths.
- B2. Correctly reports the workflow state and next action for each subcase.
- B3. Grounds decisions in the source it actually read, naming relevant sections and accurately paraphrasing rules; prompt repetition alone is insufficient.

## Gate-violation rule

Any Codex map validation, invented Claude lane reinterpretation, missing step fallback, shared path, or driver editorial judgment fails.

## Layer 2 — Quality

Only if every B-item passes, score Q1 (0–2): clarity and complete case coverage; Q2 (0–2): concise, actionable progress reporting without unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List every B-item Y/N with short quoted response evidence, then Q1/Q2. Treat an unsubstantiated source-read claim as N for B3. PASS requires all B-items.
