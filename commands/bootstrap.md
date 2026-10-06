---
description: Prepare this repo for dev-flow in one pass — gitignore for the state folder, gh auth check, branch config (main + dev names persisted to .dev-flow/config.json), and agent docs via the document-structure engine. Idempotent per component; re-runs are green no-ops that double as a health check. Standalone — not a dev-flow step.
user-invocable: false
---

# Bootstrap this repo

This file is a **thin wrapper** — it carries no workflow content and is not the single source. The single source of truth for the bootstrap flow (precheck, the five components, the closing-checklist format, error handling, the never-commit policy) is:

**`skills/bootstrap/SKILL.md` (dev-flow plugin)** — read and follow it exactly.

`$ARGUMENTS` is passed through to the skill (reserved for future use; the flow currently takes no arguments).

Why this file is thin: duplicating the flow here means two hand-synced copies that drift. Never add component content, the checklist format, or policy text back into a wrapper — edit the SKILL.md instead.