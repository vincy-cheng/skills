---
description: Start a new feat or fix through the full workflow — plan (brainstorm → spec → plan → issue) → build (execute, TDD) → verify (test → review → doc-fix) → ship (PR → manual merge → close-out). 11 steps. Pass the idea as arguments; pass nothing or "resume" to continue prior work. Maintains gitignored state files so work can resume. All step skills are dev-flow's own — no external plugin dependencies.
user-invocable: false
---

# New feature or fix — full workflow

This file is a **thin wrapper** — it carries no workflow content and is not the single source. The single source of truth for the full 11-step gated workflow (gate table, state-file template, resume rules, preflight, commit guard, every step definition) is:

**`skills/new-feature/SKILL.md` (dev-flow plugin)** — read and follow it exactly.

`$ARGUMENTS` is the input brief or resume selector, exactly as the skill's **Resume** section defines.

Why this file is thin: duplicating the workflow here means two hand-synced copies that drift. Never add step content, the gate table, or state-file templates back into a wrapper — edit the SKILL.md instead.