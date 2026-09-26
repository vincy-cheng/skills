# AGENTS.md

This repo publishes AI coding-agent plugins. There is no application code and no build step; the test suite is `tests/check.sh` (bash consistency checks). Each top-level directory is one plugin. `CLAUDE.md` is a symlink to this file so Claude Code, GitHub Copilot, and other agents all read the same guidance.

Agent-facing docs (progressive-disclosure tree): `docs/agents/INDEX.md` — start there.

## Layout convention

A plugin directory follows the plugin format:
- `.claude-plugin/plugin.json` — metadata (name, description, version, author, keywords).
- `commands/<name>.md` — slash commands, each with YAML frontmatter (`description`) and a Markdown body. `$ARGUMENTS` interpolates user input.
- `skills/<name>/SKILL.md` — skills, each with YAML frontmatter (`name`, `description`) and a Markdown body that tells the agent how to run the skill.

These skill files are Markdown consumed by AI coding agents (Claude Code, Copilot, etc.), not application source.

## Current plugin: `dev-flow`

`dev-flow` drives a feat **or fix** end-to-end in four phases — plan / build / verify / ship:
brainstorm → spec → plan → create GitHub issue → execute (TDD) → test → review → doc-fix → PR → manual merge → close-out.

- `commands/new-feature.md` — the `/new-feature` command and the pipeline of record. It defines the step sequence, the state-file format, the commit guard, and the **hard gate** that prevents invoked sub-skills from skipping or reordering dev-flow steps. Maintains an **index file** (`docs/features/.feature-states/state.md`) mirroring all runs — current/last at a glance. Called with no args (or "resume"), it reads the index and resumes the newest active run — so you don't have to remember the feat-name to continue.
- `commands/new-idea.md` + `skills/new-idea/SKILL.md` — the `/new-idea` command: scaffolds a structured brainstorm folder `ideas/<project>/<slug>/` (ideas repo) or `ideas/<slug>/` (project repo) with five fixed self-contained docs (README, research, design, **plan**, tl-dr) plus an optional **cost** doc — both the nesting level and cost inclusion are confirmed with the user up front, and the idea is **discussed and grilled with the user before any files are written** (one round: restate → grill → synthesize → explicit go-ahead). `cost.md` (when included) captures pricing/quotas; `plan.md` is a milestone-draft. Pairs with `/new-feature`: when its arguments reference an idea folder, step 1 ingests the docs as the established brief (settled choices carried forward, not re-derived), and `create-github-issue` links the folder in the issue References. Standalone like `document-structure`/`whats-new` — **not** part of the step sequence and never gated by the state file.
- `skills/brainstorm/SKILL.md` — step 1. The in-house brainstorming engine: interview (problem, kind, scope, success), idea-folder ingestion, design-tree rounds with recommended answers, 2-3 approaches with trade-offs, sectioned design presentation, spec written directly to `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md` (never committed). Standalone-capable; **no handoff** — its terminal state is the approved spec, and the hard gate advances to step 2.
- `skills/plan/SKILL.md` — step 3. The in-house contract-first plan engine: a plan is complete only when steps 4–11 can run from it alone (issue material, verbatim-copyable task list for the state file, Mermaid **Flow Chart**, per-task Files + TDD shape via the `tdd` skill). Plan saved to `docs/features/plans/YYYY-MM-DD-<feat-name>.md` (never committed). Standalone-capable; **no handoff** — its terminal state is the approved plan, and the hard gate advances to step 4. In-house replacement for superpowers' writing-plans skill.
- `skills/create-github-issue/SKILL.md` — step 4. Drafts a GitHub issue from a spec/plan, shows the draft for user confirmation, then publishes via `gh issue create`. Branch naming: `feat/<issue-number>-<name>` or `fix/<issue-number>-<name>` off `dev` (if no `dev`, asks before doing anything — create it off the default branch, or branch off the default branch directly).
- `skills/execute-tasks/SKILL.md` — step 5. Own task loop (TDD via the `tdd` skill); progress in the state file; commits per task. Two modes: inline or subagent (fresh implementer per task for isolation) — **recommends** one from the plan's task shape (count, file spread, coupling) with a user override, not a bare "which mode?". Implement step carries a one-line clean-code pointer (prevention, with review as backstop). All artifacts under `docs/features/` — no `.superpowers/` workspace.
- `skills/tdd/SKILL.md` — dev-flow's test-first engine: red-green loop, seams, anti-patterns, rationalizations. Invoked by execute-tasks per task (step 5); also runs standalone in any repo. Refactor is not a loop phase — review (step 7) is the refactor gate.
- `skills/test/SKILL.md` — step 6. Fresh-subagent test gate: full suite + lint + test-honesty scan; green/red verdict; red returns to execute. Also runs standalone.
- `skills/review/SKILL.md` — step 7. Pre-PR judgment review gate via a fresh independent reviewer subagent (fresh eyes, no author bias; spec coverage, obvious issues — bugs, security smells, leftover, naming — plus a maintainability pass with a clean-code check: structure, coupling, naming, complexity, duplication, functions, conditionals, comments, code smells, KISS, DRY). Also runs standalone. Doesn't run the test suite — that's the test skill (step 6).
- `skills/doc-fix/SKILL.md` — step 8. Pre-PR doc-drift gate: scans this plugin's docs and the target repo's docs for drift caused by *this* run, guided (edits shown before applying), commits as `docs:` riding in the PR. Also runs standalone.
- `skills/open-pr/SKILL.md` — step 9. Opens the PR targeting `dev`: body draft, closing keyword, issue-sidebar link, issue-body sync (acceptance boxes + `PR: #NN`), standalone mode. Never merges.
- `skills/commit/SKILL.md` — Conventional Commits messages from the diff with **no AI attribution** in the message or trailers. Runs standalone ("commit this") or per-task during step 5.
- `skills/document-structure/SKILL.md` — generates/maintains the **target repo's** agent-facing docs as a layered progressive-disclosure tree under `docs/agents/`: a tiny always-load index, core maps (architecture, dev-ops), plus dynamic concern maps discovered from the project (testing, API, deployment, database, auth, …), optional deep-detail files. Runs standalone in any repo; not part of the step sequence. Update mode scopes itself by git history since the newest map footer (optionally via `whats-new`).
- `skills/whats-new/SKILL.md` — on-demand summary of what's new in a repo: recent shipped work (git log + gh PRs/issues) **and** current doc-vs-code drift. Returns a view — never writes a record. Triggers on "what's new", "catch me up on this repo".
- **Step 8 doc-fix** — pre-PR: find doc drift caused by *this* run (this plugin's docs, the target repo's docs) and fix it; the fixes ride in the PR as `docs:` commits. Guided: proposed edits shown before applying. No drift → no-op pass. Replaces the old post-merge distill so a run's own doc drift ships in the same PR, not after. Now its own skill at `skills/doc-fix/SKILL.md`.
- **Step 11 close-out** — post-merge: update persisted memory with durable cross-session facts if any; offer to delete the merged branch (check out `dev` first, then local `git branch -d` + remote `git push origin --delete`, only with the user's yes); mark the run `done`. No doc edits here (those moved to step 8). No memory update needed → say so and mark done.

### Fully self-contained — no peer dependencies

Every step's engine is dev-flow's own skill (`brainstorm`, `plan`, `tdd`, `execute-tasks`, `test`, `review`, `doc-fix`, `open-pr`, `create-github-issue`, `commit`), so all artifacts stay under `docs/features/` with no `.superpowers/` workspace. dev-flow declares no peer dependencies in `plugin.json` and requires no other plugin to be installed. The workflow shape was originally inspired by obra/superpowers (see the README's Acknowledgements); every borrowed piece has since been replaced in-house.

### How the pieces fit together

`/new-feature` is the orchestrator; it invokes its own skills for every step (`brainstorm` runs step 1, `plan` runs step 3; execute-tasks — which invokes tdd per task — test, review, doc-fix, open-pr, create-github-issue, commit). Sub-skills have their own "next step" instructions. Per `commands/new-feature.md`, those handoffs do **not** advance, skip, or reorder dev-flow steps — control always returns to the next dev-flow step.

The **hard gate** enforces this structurally: each step reads the state file's **Goal status** on entry and refuses to run unless it matches the expected incoming status, then sets the next status. A sub-skill handoff that tries to jump ahead hits the gate and bounces back to the correct step. The state file (`docs/features/.feature-states/<feat>.state.md`) is the source of truth for which step a piece of work is on.

## Editing these skills

Preserve:
- The exact YAML frontmatter (`---` fences) at the top of each file — the `description` field drives skill triggering and must stay accurate.
- The hard gate in `commands/new-feature.md` — the step→incoming-status→sets-status mapping and the gate check that runs on every step entry. This is the workflow's backbone.
- The Mermaid flow-chart requirement in `skills/plan/SKILL.md` (the plan skill's `## Flow Chart` section mandates the chart in every generated plan; `tests/check.sh` check 8 guards it).
- The state-file template and lifecycle (`brainstorm` → `spec` → `planning` → `issue` → `execute` → `test` → `review` → `doc-fix` → `pr-review` → `merged` → `done`).

When changing one step's behavior, update both `commands/new-feature.md` (the step description and gate) and the relevant sub-skill (`skills/.../SKILL.md`) so the two stay consistent.

## Git workflow

Published to `github.com/vincy-cheng/skills`. No project-specific scripts or hooks beyond the global agent setup.