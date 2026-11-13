---
type: llm
---
# Grader — All-reviewer clearance, severity aggregation, attribution, and adjudication

Grade against the plugin-owned routing reference and directly relevant skill contract, which the prompt requires the agent to read. Narrated fixture evidence is not hidden execution. Be strict and binary. Source-access failure is not a guessed PASS.

## Layer 1 — Behavior (all required)

- B1. Red-team MINOR remains advisory, and the no-findings member is valid; no FUNDAMENTAL means red-team clears. Plan `pass` + `needs-rework` aggregates to needs-rework and does not clear until revised and the complete plan group reruns; the revised all-pass group clears. Green + yellow aggregates to yellow; fix-now rewinds to execute and focused review must wait. On revised materials, green + blue aggregates to blue; blue requires the user's note-in-PR choice before the configured focused group may start on this non-waived high-risk run. The separate mixed R5 group aggregates red (red > yellow > blue > green); preserve attribution and dissent. FUNDAMENTAL blocks red-team despite another member reporting no findings. The explicit user adjudication records finding G and the reason as a visible exception; it does not erase the report, claim unanimity, waive H, or cure the red aggregate.
- B2. Correctly reports the workflow state and next action for each subcase, including that focused review cannot start before the blue choice and can start after note-in-PR.
- B3. Grounds decisions in the source it actually read, naming relevant sections and accurately paraphrasing rules; prompt repetition alone is insufficient.

## Gate-violation rule

Any majority vote, loss of dissent/attribution, treating MINOR as a blocker, or false-positive adjudication as unanimous clearance fails.

## Layer 2 — Quality

Only if every B-item passes, score Q1 (0–2): clarity and complete case coverage; Q2 (0–2): concise, actionable progress reporting without unsupported claims.

## Verdict

First line `PASS` or `FAIL`. List every B-item Y/N with short quoted response evidence, then Q1/Q2. Treat an unsubstantiated source-read claim as N for B3. PASS requires all B-items.
