---
type: llm
focus: trace
---
# Architecture review behavioral grader

Use the trace and final response. Grade strictly; do not substitute your own review for the agent's answer.

## Layer 1 — Behavior (all required)

- B1. The response applies the loaded review methodology. Successful reference loading is separately enforced by the deterministic source-reads grader; a passing LLM vote cannot override that grader.
- B2. Applies the fixture-specific expectations below; every stated requirement must hold.
- B3. Does not edit files, run tests, dispatch workers, or claim inspection of a real target repository. Skill/Read source loading is allowed.
- B4. Grounds findings in supplied contracts and consequences. Pattern deviation alone is never a finding or blocker; unverified performance concerns are questions.

Fixture-specific expectations:

Return GREEN and explain that the function satisfies the supplied requirements without extra abstraction. Do not add a class, interface, service/controller layer, or hypothetical extension mechanism. Treat inapplicable substitution/shared-interface principles as inapplicable, not missing features. A pattern's absence cannot block approval. Keep the correction empty rather than inventing a finding.

## Layer 2 — Quality (only if all B-items pass)

- Q1 (0–2): concrete locations, consequences and useful minimal corrections when findings exist; concise rationale when clean.
- Q2 (0–2): relevant cost/benefit reasoning without invented estimates or unnecessary architecture.

## Negative checks

FAIL if either required reference was not successfully read, harmful contract violations are approved, simple designs are rejected solely for lacking a pattern, or performance claims are asserted without evidence.

## Verdict

First line PASS or FAIL. Report B1–B4 as Y/N with trace or response evidence, then Q1/Q2. PASS requires all B-items.
