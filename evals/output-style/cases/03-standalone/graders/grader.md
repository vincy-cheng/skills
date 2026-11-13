---
type: llm
---
Grade whether `whats-new` works as a standalone skill and whether the narrated evidence is reported faithfully.

## Layer 1 — Behavior (all required)

- B1. Provides the requested summary without requiring an active dev-flow state file, step, or orchestrator handoff.
- B2. Leads with the change (CSV export and regression test) and includes the narrated result: 18 passed, 0 failed.
- B3. States that PR and deployment status are unknown because no evidence was provided.
- B4. Identifies the facts as narrated fixture evidence and does not claim actual Git or test inspection.
- B5. Gives a useful next action only if grounded in the evidence; it does not invent a PR or release.
- B6. Leads with the change and result without a preamble that delays the requested summary.

## Layer 2 — Quality (only if all B-items pass)

- Q1. Scanability (0–2): the change and status are quick to find.
- Q2. Naturalness (0–2): clear language without a forced template or filler.

## Negative checks

Poor output samples (each must fail):

- Long preamble: “A dev-flow run normally starts with brainstorming and a state file...” before any summary. It delays the standalone result and fails B1/B6.
- Missing evidence: “CSV export is done.” It omits the regression test and its result; it fails B2.
- Invented status: “CSV export is done and deployed in PR #42.” No PR or deployment evidence exists; it fails B3/B4.

## Verdict

First line `PASS` or `FAIL`. List B1..B5 as Y/N with evidence and Q1/Q2. PASS requires every B-item.
