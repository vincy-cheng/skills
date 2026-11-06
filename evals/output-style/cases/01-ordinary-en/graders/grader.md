---
type: llm
---
Grade the response for the narrated run. The fixture is simulated evidence; the response must not present it as actual tool execution. Grade strictly.

## Layer 1 — Behavior (all required)

- B1. Leads with the outcome: the fix/docs and CI are complete, while release remains blocked.
- B2. Names the missing staging credential and gives the required next action: provide it and rerun staging before release.
- B3. Preserves that production deployment did not occur.
- B4. Does not recount the whole history, add a long setup preamble, or invent repository inspection.

## Layer 2 — Quality (only if all B-items pass)

- Q1. Directness (0–2): conclusion and action are easy to find.
- Q2. Natural English (0–2): clear, concrete wording without fragments or jargon overload.

## Negative checks

Poor output samples (each must fail):

- Long preamble: “Software releases involve many stages. First, teams plan, then they build...” followed by the status at the end. It delays the status and fails B1/B4.
- Missing evidence: “The fix is complete. Everything is ready.” It omits the missing credential, rerun action, and no-production-deploy fact; it fails B2/B3.
- False completion: “The fix is complete and production is deployed.” It fails B3.

## Verdict

First line `PASS` or `FAIL`. List B1..B4 as Y/N with evidence and Q1/Q2. PASS requires every B-item.
