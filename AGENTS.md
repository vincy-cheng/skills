# AGENTS.md

This repo publishes AI coding-agent plugins. There is no application code, no build step, and no test suite. Each top-level directory is one plugin. `CLAUDE.md` is a symlink to this file so Claude Code, GitHub Copilot, and other agents all read the same guidance.

## Layout convention

A plugin directory follows the plugin format:
- `.claude-plugin/plugin.json` — metadata (name, description, version, author, keywords, optional `peerDependencies`).
- `commands/<name>.md` — slash commands, each with YAML frontmatter (`description`) and a Markdown body. `$ARGUMENTS` interpolates user input.
- `skills/<name>/SKILL.md` — skills, each with YAML frontmatter (`name`, `description`) and a Markdown body that tells the agent how to run the skill.

These skill files are Markdown consumed by AI coding agents (Claude Code, Copilot, etc.), not application source.

## Current plugin: `dev-flow`

`dev-flow` drives a feature **or fix** end-to-end:
brainstorm → spec → plan → create GitHub issue → execute (TDD) → review → PR → manual merge → distill (update docs if needed).

- `commands/new-feature.md` — the `/new-feature` command and the pipeline of record. It defines the step sequence, the state-file format, the commit guard, and the **hard gate** that prevents invoked sub-skills from skipping or reordering dev-flow steps. Maintains an **index file** (`docs/features/.feature-states/state.md`) mirroring all runs — current/last at a glance. Called with no args (or "resume"), it reads the index and resumes the newest active run — so you don't have to remember the feat-name to continue.
- `commands/new-idea.md` + `skills/new-idea/SKILL.md` — the `/new-idea` command: scaffolds a structured brainstorm folder `ideas/<project>/<slug>/` (ideas repo) or `ideas/<slug>/` (project repo) with five fixed self-contained docs (README, research, design, **plan**, tl-dr) plus an optional **cost** doc — both the nesting level and cost inclusion are confirmed with the user up front, and the idea is **discussed and grilled with the user before any files are written** (one round: restate → grill → synthesize → explicit go-ahead). `cost.md` (when included) captures pricing/quotas; `plan.md` is a milestone-draft. Pairs with `/new-feature`: when its arguments reference an idea folder, step 1 ingests the docs as the established brief (settled choices carried forward, not re-derived), and `create-github-issue` links the folder in the issue References. Standalone like `document-structure`/`whats-new` — **not** part of the step sequence and never gated by the state file.
- `skills/create-github-issue/SKILL.md` — step 4. Drafts a GitHub issue from a spec/plan, shows the draft for user confirmation, then publishes via `gh issue create`. Branch naming: `feature/<issue-number>-<name>` or `fix/<issue-number>-<name>` off `dev` (falls back to default branch if no `dev`).
- `skills/execute-tasks/SKILL.md` — step 5. Own TDD loop; progress in the state file; commits per task. Two modes: inline (default) or subagent (fresh implementer per task for isolation). All artifacts under `docs/features/` — no `.superpowers/` workspace.
- `skills/review/SKILL.md` — step 5.5. Pre-PR self-review gate (test green, spec coverage, obvious issues). Also runs standalone.
- `skills/commit/SKILL.md` — Conventional Commits messages from the diff with **no AI attribution** in the message or trailers. Runs standalone ("commit this") or per-task during step 5.
- `skills/document-structure/SKILL.md` — generates/maintains the **target repo's** agent-facing docs as a layered progressive-disclosure tree under `docs/agents/`: a tiny always-load index, core maps (architecture, dev-ops), plus dynamic concern maps discovered from the project (testing, API, deployment, database, auth, …), optional deep-detail files. Runs standalone in any repo; not part of the step sequence. Update mode scopes itself by git history since the newest map footer (optionally via `whats-new`).
- `skills/whats-new/SKILL.md` — on-demand summary of what's new in a repo: recent shipped work (git log + gh PRs/issues) **and** current doc-vs-code drift. Returns a view — never writes a record. Triggers on "what's new", "catch me up on this repo".
- **Step 8 distill** — after merge, review the completed work and update docs (this plugin's, the target repo's, or persisted memory) if it revealed a gap, pattern, or correction worth keeping. Guided: proposed edits shown to the user before applying; `docs:` commit separate from code. No edits needed → mark the run done.

### Peer dependency: `superpowers`

`dev-flow` invokes three skills from the **superpowers** plugin: `superpowers:brainstorming`, `superpowers:writing-plans`, and `superpowers:test-driven-development`. Per-task execution and review are dev-flow's own (`execute-tasks` — with an inline mode and a subagent mode — and `review`), so all artifacts stay under `docs/features/` with no `.superpowers/` workspace. Superpowers must be installed alongside dev-flow. This is declared in `dev-flow/.claude-plugin/plugin.json` as a `peerDependency` and documented in the README.

**Superpowers defaults lose to dev-flow.** Superpowers' SessionStart injection urges invoking its skills before any response, and its skills carry their own defaults (`docs/superpowers/` save paths, design-doc commits, "Execution Handoff"). Inside a dev-flow run those defaults do not apply: files go under `docs/features/` (never `docs/superpowers/`), specs/plans/state are never committed, and step order is governed solely by the hard gate in `commands/new-feature.md`.

### How the pieces fit together

`/new-feature` is the orchestrator; it invokes superpowers skills as sub-steps (brainstorming, writing-plans) plus its own skills (execute-tasks, review, create-github-issue, commit). The superpowers sub-skills have their own handoff/next-step instructions (e.g. `writing-plans`'s "Execution Handoff"). Per `commands/new-feature.md`, those handoffs do **not** advance, skip, or reorder dev-flow steps — control always returns to the next dev-flow step.

The **hard gate** enforces this structurally: each step reads the state file's **Goal status** on entry and refuses to run unless it matches the expected incoming status, then sets the next status. A sub-skill handoff that tries to jump ahead hits the gate and bounces back to the correct step. The state file (`docs/features/.feature-states/<feat>.state.md`) is the source of truth for which step a piece of work is on.

## Editing these skills

Preserve:
- The exact YAML frontmatter (`---` fences) at the top of each file — the `description` field drives skill triggering and must stay accurate.
- The hard gate in `commands/new-feature.md` — the step→incoming-status→sets-status mapping and the gate check that runs on every step entry. This is the workflow's backbone.
- The Mermaid flow-chart requirement in `commands/new-feature.md` (step 3 mandates a `## Flow Chart` block in every generated plan).
- The state-file template and lifecycle (`brainstorm` → `spec` → `planning` → `issue` → `execute` → `review` → `pr-review` → `merged` → `distill`).

When changing one step's behavior, update both `commands/new-feature.md` (the step description and gate) and the relevant sub-skill (`skills/.../SKILL.md`) so the two stay consistent.

## Git workflow

Published to `github.com/vincy-cheng/skills`. No project-specific scripts or hooks beyond the global agent setup.