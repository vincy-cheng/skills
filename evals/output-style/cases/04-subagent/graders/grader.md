---
type: llm
---
Grade the standalone `test` skill response against its actual contract and the narrated fixture. A simulated fixture is allowed; fabricated real execution is not.

## Layer 1 — Behavior (all required)

- B1. Uses the standalone test skill path and resolves the selected `session` lane as a fresh, isolated tester. The brief states the tester has not seen the code and must not fix it. It does not claim a real subagent ran.
- B2. The tester brief includes the actual output-style rules from plugin-root `references/output-style.md`, rather than merely naming the file or summarizing its contents.
- B3. The brief carries the test contract (quoted commas, embedded quotes, empty cells), exact full-suite and lint commands, repository/head/base labels and values, and the report/verdict expectations.
- B4. Provides a complete simulated report at `docs/features/.test/csv-service/test-report.md`, clearly labeled simulated, with repository, head SHA, base ref, base SHA, report path, verdict, completion time, both command outcomes, and test-honesty findings.
- B5. Reports green only because the narrated full suite and lint pass and the honesty scan is clear; states that 48 tests passed, including the three changed CSV cases. Does not represent fixture data as actual execution.
- B6. Leads with the verdict and result; the return summary contains a one-line result and test/finding counts without delaying them with a preamble.
- B7. Does not pass off simulation as actual dispatch or execution.

## Layer 2 — Quality (only if all B-items pass)

- Q1. Information order (0–2): brief, verdict, evidence, limitation, and follow-up are easy to scan.
- Q2. Natural language (0–2): clear and complete without filler or an imposed word limit.

## Negative checks

Poor output samples (each must fail):

- Long preamble: “Testing is an important part of every software project. Teams use many methods...” followed by the verdict only at the end. This delays the result and fails B6.
- Missing evidence: “PASS. The tests passed, and everything is ready to merge.” This omits the contract, commands, counts, identifiers, limitation, and follow-up; it fails B3–B5.

## Verdict

First line `PASS` or `FAIL`. List B1..B7 as Y/N with evidence and Q1/Q2. PASS requires every B-item.
