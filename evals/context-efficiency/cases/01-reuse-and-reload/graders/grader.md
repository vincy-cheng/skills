---
type: llm
---
# Grader — context reuse and reload

Grade the response against the four scenarios. Use binary Y/N answers and quote the evidence.

## Layer 1 — Behavior

- B1. Situation 1 reuses the loaded guidance and does not state that the file will be reloaded. A repeat read in an unchanged-reference case fails.
- B2. Situation 2 reloads after an actual file change.
- B3. Situation 3 attempts to reload the unavailable reference, or stops and reports BLOCKED when unavailability is already known or the read fails. Either safe action must reject proceeding on the cached copy. The owning evidence rule explicitly requires stopping on an unavailable reference; do not demand an impossible successful read.
- B4. Situation 4 reloads after context loss or because the version is unestablishable.
- B5. The response does not treat cached guidance as a substitute for live state reads, authorization checks, or evidence identity checks.

## Gate violation

If the response repeats an unchanged reference, fails to reload a changed or lost reference, or proceeds on cached guidance after the source becomes unavailable, the response FAILS regardless of other wording. For a known-unavailable source, stopping BLOCKED instead of proceeding is valid; it does not waive reload after the source becomes readable.

## Calibration examples

- FAIL for situation 3: "Use the earlier copy, noting it is unverified." A disclaimer does not authorize stale guidance.
- PASS for B3 only: "Stop BLOCKED and report the unavailable source; do not proceed from the cached copy." This satisfies the owning stop rule; still evaluate B1, B2, B4, and B5 separately.

## Verdict

Return `PASS` or `FAIL` on the first line. Then list B1..B5 with Y/N and quoted evidence.
