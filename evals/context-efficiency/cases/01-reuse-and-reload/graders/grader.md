---
type: llm
---
# Grader — context reuse and reload

Grade the response against the four scenarios. Use binary Y/N answers and quote the evidence.

## Layer 1 — Behavior

- B1. Situation 1 reuses the loaded guidance and does not state that the file will be reloaded. A repeat read in an unchanged-reference case fails.
- B2. Situation 2 reloads after an actual file change.
- B3. Situation 3 reloads because the reference is unavailable.
- B4. Situation 4 reloads after context loss or because the version is unestablishable.
- B5. The response does not treat cached guidance as a substitute for live state reads, authorization checks, or evidence identity checks.

## Gate violation

If the response repeats an unchanged reference or fails to reload a changed, unavailable, or lost reference, the response FAILS regardless of other wording.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B5 with Y/N and quoted evidence.
