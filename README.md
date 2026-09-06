# skills

AI coding-agent plugins published from this repo. Each top-level directory is one Claude Code plugin.

## Install

`dev-flow` depends on the `superpowers` plugin (it calls `superpowers:brainstorming`, `superpowers:writing-plans`, and `superpowers:test-driven-development`). Install superpowers first, then dev-flow:

```
/plugin install superpowers
/plugin install vincy-cheng/skills
```

Or from a git URL:

```
claude plugin install https://github.com/obra/superpowers.git
claude plugin install https://github.com/vincy-cheng/skills.git
```

Then run `/new-feature <your idea>` in any repo with the `gh` CLI. Run `/new-feature` with no args to **resume** — it finds your last run for you.

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
| `create-github-issue` skill | Step 4 — draft → confirm → `gh issue create` | Inside the flow |
| `execute-tasks` skill | Step 5 — TDD loop, commit per task. Inline or subagent mode | Inside the flow |
| `review` skill | Step 5.5 — pre-PR gate: tests green, spec covered, obvious issues | Inside the flow, or standalone |
| `commit` skill | Conventional Commits from the diff, **no AI attribution** | Standalone, or per-task in step 5 |
| `document-structure` skill | Builds/updates the target repo's agent docs under `docs/agents/` — tiny index + architecture/dev-ops maps + dynamic concern maps (testing, API, deployment, database, …) | Any repo, on demand |
| `whats-new` skill | Summarizes what's new in a repo: shipped work (git + PRs/issues) + doc-vs-code drift. Never writes a changelog file | Any repo, on demand |

### Requires: the `superpowers` plugin

`dev-flow` invokes `superpowers:brainstorming`, `superpowers:writing-plans`, and `superpowers:test-driven-development`. Install superpowers first.

**One thing to know:** superpowers injects a session-start instruction urging skill use before any response. Inside a dev-flow run, ignore it — dev-flow calls the superpowers skills it needs as sub-steps, and superpowers' defaults (`docs/superpowers/` paths, design-doc commits, "Execution Handoff") **don't apply**. Everything lives under `docs/features/` (gitignored, never committed).

## Acknowledgements

`dev-flow` builds on [obra/superpowers](https://github.com/obra/superpowers) (available in Claude Code's official plugin marketplace). Dev-flow reuses three of its skills — `brainstorming`, `writing-plans`, and `test-driven-development` — as sub-steps inside its own pipeline, and adds its own `execute-tasks`, `review`, `create-github-issue`, and `commit` skills so all artifacts stay under `docs/features/` with no `.superpowers/` workspace. Many thanks to the creator and maintainers of superpowers — dev-flow leans on their work for brainstorming, planning, and TDD.

## Repo layout

```
dev-flow/
├── .claude-plugin/plugin.json      # metadata + peerDependencies.superpowers
├── commands/new-feature.md         # /new-feature — pipeline + hard gate
└── skills/
    ├── commit/SKILL.md             # Conventional Commits, no AI attribution
    ├── create-github-issue/SKILL.md
    ├── document-structure/SKILL.md # agent-facing doc tree generator (docs/agents/)
    ├── execute-tasks/SKILL.md      # step 5: TDD loop, inline or subagent
    ├── review/SKILL.md             # step 5.5: pre-PR self-review gate
    └── whats-new/SKILL.md          # "what's new" summary: history + doc-drift check
```

`AGENTS.md` is the agent guidance for this repo; `CLAUDE.md` is a symlink to it so Claude Code, Copilot, and others read the same file.