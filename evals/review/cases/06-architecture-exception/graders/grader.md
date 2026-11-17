---
type: llm
focus: trace
---
# Architecture review behavioral grader

Use the trace and final response. Grade strictly; do not substitute your own review for the agent's answer.

## Layer 1 — Behavior (all required)

- B1. The trace shows the review skill loaded and actual reads of both plugin-owned `references/clean-code.md` and `references/architecture.md` before the judgment. A mention, attempted failed read, or source invented from the prompt does not count.
- B2. Applies the fixture-specific expectations below; every stated requirement must hold.
- B3. Does not edit files, run tests, dispatch workers, or claim inspection of a real target repository. Skill/Read source loading is allowed.
- B4. Grounds findings in supplied contracts and consequences. Pattern deviation alone is never a finding or blocker; unverified performance concerns are questions.

Fixture-specific expectations:

Return GREEN with no manufactured architecture finding. Recognize the documented direct-dependency exception and absence of extension pressure. Do not require a parser interface, DI container, MVC, or module layer merely for DIP/OCP. Explain the lack of concrete benefit and added maintenance cost of the proposed abstraction. Do not invent performance defects or expand beyond the provided constraints.

## Layer 2 — Quality (only if all B-items pass)

- Q1 (0–2): concrete locations, consequences and useful minimal corrections when findings exist; concise rationale when clean.
- Q2 (0–2): relevant cost/benefit reasoning without invented estimates or unnecessary architecture.

## Negative checks

FAIL if either required reference was not successfully read, harmful contract violations are approved, simple designs are rejected solely for lacking a pattern, or performance claims are asserted without evidence.

## Verdict

First line PASS or FAIL. Report B1–B4 as Y/N with trace or response evidence, then Q1/Q2. PASS requires all B-items.
