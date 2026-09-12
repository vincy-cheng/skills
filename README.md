# skills

AI coding-agent plugins published from this repo. Each top-level directory is one Claude Code plugin.

## Install

`dev-flow` depends on the `superpowers` plugin (it calls `superpowers:brainstorming`, `superpowers:writing-plans`, and `superpowers:test-driven-development`). Install superpowers first, then dev-flow:

```
/plugin marketplace add vincy-cheng/skills
/plugin install superpowers
/plugin install dev-flow@vincy-skills
```

Alternatively, install dev-flow directly from the git URL:

```
claude plugin install https://github.com/vincy-cheng/skills.git
```

Then run `/new-feature <your idea>` in any repo with the `gh` CLI. Run `/new-feature` with no args to **resume** — it finds your last run for you.

The same install also gives you `/new-idea` — dev-flow's structured brainstorm command (see below).

> If you see a "missing peer dependency: superpowers" prompt, run `/plugin install superpowers` and retry — dev-flow can't run its brainstorm/plan/TDD steps without it.

## Plugin: `dev-flow`

Drives a feature **or fix** end-to-end:

```
brainstorm → spec → plan → issue → execute (TDD) → review → PR → merge → distill
```

Three guarantees:
- **Hard gate** — sub-skills can't skip or reorder steps.
- **Resumable** — gitignored state files + an index file (`docs/features/.feature-states/state.md`) track every run.
- **Local artifacts** — specs/plans/state live under `docs/features/`, never committed.

### What it provides

| Piece | What it does | When |
|-------|--------------|------|
| `/new-feature` command | The pipeline of record — runs all 9 steps in order | Start or resume any feature/fix |
| `/new-idea` command | Scaffolds `ideas/<slug>/` with five docs (README, research, design, plan, tl-dr) + optional `cost.md` | Brainstorm an idea before committing to build it |
| `create-github-issue` skill | Step 4 — draft → confirm → `gh issue create` | Inside the flow |
| `execute-tasks` skill | Step 5 — TDD loop, commit per task. Inline or subagent mode | Inside the flow |
| `review` skill | Step 5.5 — pre-PR gate via a fresh reviewer subagent: tests green, spec covered, obvious issues | Inside the flow, or standalone |
| `commit` skill | Conventional Commits from the diff, **no AI attribution** | Standalone, or per-task in step 5 |
| `document-structure` skill | Builds/updates the target repo's agent docs under `docs/agents/` — tiny index + architecture/dev-ops maps + dynamic concern maps (testing, API, deployment, database, …) | Any repo, on demand |
| `whats-new` skill | Summarizes what's new in a repo: shipped work (git + PRs/issues) + doc-vs-code drift. Never writes a changelog file | Any repo, on demand |

### Requires: the `superpowers` plugin

`dev-flow` invokes `superpowers:brainstorming`, `superpowers:writing-plans`, and `superpowers:test-driven-development`. Install superpowers first.

**One thing to know:** superpowers injects a session-start instruction urging skill use before any response. Inside a dev-flow run, ignore it — dev-flow calls the superpowers skills it needs as sub-steps, and superpowers' defaults (`docs/superpowers/` paths, design-doc commits, "Execution Handoff") **don't apply**. Everything lives under `docs/features/` (gitignored, never committed).

## dev-flow's brainstorm command: `/new-idea`

Scaffolds a structured brainstorm folder for a product or concept:

```
ideas/<slug>/ — README · research · (cost) · design · plan · tl-dr
```

Five self-contained docs by default, no ad-hoc file names; a sixth, `cost.md`, when you opt in — the skill asks up front whether to include cost research (live pricing verification). `cost.md` captures pricing/quotas/limits, and `plan.md` is a milestone-draft plan you can hand straight to `/new-feature` when you're ready to build.

Run `/new-idea <your idea>` in any repo — it asks whether the folder nests by project (ideas repo: `ideas/<project>/<slug>/`) or sits flat (project repo: `ideas/<slug>/`), and whether to include a `cost.md`. Before writing anything it **discusses the idea with you** — one grill round (who's it for, smallest version, hard part), a synthesis, and an explicit go-ahead — so the docs record the settled idea, not your first prompt. It pairs with the pipeline: brainstorm with `/new-idea`, then build with `/new-feature ideas/<slug>` — step 1 ingests the folder's docs as its brief, and the GitHub issue links back to the folder.

## Acknowledgements

`dev-flow` builds on [obra/superpowers](https://github.com/obra/superpowers) (available in Claude Code's official plugin marketplace). Dev-flow reuses three of its skills — `brainstorming`, `writing-plans`, and `test-driven-development` — as sub-steps inside its own pipeline, and adds its own `execute-tasks`, `review`, `create-github-issue`, and `commit` skills so all artifacts stay under `docs/features/` with no `.superpowers/` workspace. Many thanks to the creator and maintainers of superpowers — dev-flow leans on their work for brainstorming, planning, and TDD.

## Repo layout

```
dev-flow/
├── .claude-plugin/plugin.json      # metadata + peerDependencies.superpowers
├── commands/new-feature.md         # /new-feature — pipeline + hard gate
├── commands/new-idea.md            # /new-idea — scaffold an idea folder (standalone)
└── skills/
    ├── commit/SKILL.md             # Conventional Commits, no AI attribution
    ├── create-github-issue/SKILL.md
    ├── document-structure/SKILL.md # agent-facing doc tree generator (docs/agents/)
    ├── execute-tasks/SKILL.md      # step 5: TDD loop, inline or subagent
    ├── new-idea/SKILL.md           # idea-folder scaffold: fixed slots + optional cost.md + draft plan
    ├── review/SKILL.md             # step 5.5: pre-PR review via fresh subagent
    └── whats-new/SKILL.md          # "what's new" summary: history + doc-drift check
```

`AGENTS.md` is the agent guidance for this repo; `CLAUDE.md` is a symlink to it so Claude Code, Copilot, and others read the same file.