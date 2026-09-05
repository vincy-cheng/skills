# AGENTS.md

This repo publishes AI coding-agent plugins. There is no application code, no build step, and no test suite. Each top-level directory is one plugin. `CLAUDE.md` is a symlink to this file so Claude Code, GitHub Copilot, and other agents all read the same guidance.

## Layout convention

A plugin directory follows the plugin format:
- `.claude-plugin/plugin.json` — metadata (name, description, version, author, keywords, optional `peerDependencies`).
- `commands/<name>.md` — slash commands, each with YAML frontmatter (`description`) and a Markdown body. `$ARGUMENTS` interpolates user input.
- `skills/<name>/SKILL.md` — skills, each with YAML frontmatter (`name`, `description`) and a Markdown body that tells the agent how to run the skill.

These skill files are Markdown consumed by AI coding agents (Claude Code, Copilot, etc.), not application source.

## Current plugin: `dev-flow`

`dev-flow` drives a feature **or fix** end-to-end across 7 steps:
brainstorm → spec → plan → create GitHub issue → execute (TDD) → PR → manual merge.

- `commands/new-feature.md` — the `/new-feature` command and the pipeline of record. It defines the 7-step sequence, the state-file format, the commit guard, and the **hard gate** that prevents invoked sub-skills from skipping or reordering dev-flow steps.
- `skills/create-github-issue/SKILL.md` — step 4's sub-skill. Drafts a GitHub issue from a spec/plan, shows the draft for user confirmation, then publishes via `gh issue create`. Branch naming: `feature/<issue-number>-<name>` or `fix/<issue-number>-<name>` off `dev` (falls back to default branch if no `dev`).
- `skills/commit/SKILL.md` — Conventional Commits messages from the diff with **no AI attribution** in the message or trailers. Runs standalone ("commit this") or per-task during step 5.

### Peer dependency: `superpowers`

`dev-flow` invokes skills from the **superpowers** plugin (`superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:subagent-driven-development`, `superpowers:test-driven-development`, `superpowers:finishing-a-development-branch`). Superpowers must be installed alongside dev-flow. This is declared in `dev-flow/.claude-plugin/plugin.json` as a `peerDependency` and documented in the README.

### How the pieces fit together

`/new-feature` is the orchestrator; it invokes superpowers skills as sub-steps. Those sub-skills have their own handoff/next-step instructions (e.g. `writing-plans`'s "Execution Handoff", `subagent-driven-development`'s handoff to `finishing-a-development-branch`, `finishing-a-development-branch`'s local-merge menu). Per `commands/new-feature.md`, those handoffs do **not** advance, skip, or reorder dev-flow steps — control always returns to the next dev-flow step (1→7).

The **hard gate** enforces this structurally: each step reads the state file's **Goal status** on entry and refuses to run unless it matches the expected incoming status, then sets the next status. A sub-skill handoff that tries to jump ahead hits the gate and bounces back to the correct step. The state file (`docs/features/.feature-states/<feat>.state.md`) is the source of truth for which step a piece of work is on.

## Editing these skills

Preserve:
- The exact YAML frontmatter (`---` fences) at the top of each file — the `description` field drives skill triggering and must stay accurate.
- The hard gate in `commands/new-feature.md` — the step→incoming-status→sets-status mapping and the gate check that runs on every step entry. This is the workflow's backbone.
- The Mermaid flow-chart requirement in `commands/new-feature.md` (step 3 mandates a `## Flow Chart` block in every generated plan).
- The state-file template and lifecycle (`brainstorm` → `spec` → `planning` → `issue` → `execute` → `pr-review` → `merged`).

When changing one step's behavior, update both `commands/new-feature.md` (the step description and gate) and the relevant sub-skill (`skills/.../SKILL.md`) so the two stay consistent.

## Git workflow

Published to `github.com/vincy-cheng/skills`. No project-specific scripts or hooks beyond the global agent setup.