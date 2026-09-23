# skills

AI coding-agent plugins published from this repo. Each top-level directory is one Claude Code plugin.

## Install

`dev-flow` depends on the `superpowers` plugin (it calls `superpowers:writing-plans`; its brainstorm and TDD loops are dev-flow's own `brainstorm` and `tdd` skills). Install superpowers first, then dev-flow:

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

> If you see a "missing peer dependency: superpowers" prompt, run `/plugin install superpowers` and retry — dev-flow can't run its plan step without it.

## Plugin: `dev-flow`

Drives a feat **or fix** end-to-end:

```
brainstorm → spec → plan → issue → execute (TDD) → test → review → doc-fix → PR → merge → close-out
```

Three guarantees:
- **Hard gate** — sub-skills can't skip or reorder steps.
- **Resumable** — gitignored state files + an index file (`docs/features/.feature-states/state.md`) track every run.
- **Local artifacts** — specs/plans/state live under `docs/features/`, never committed.

### What it provides

| Piece | What it does | When |
|-------|--------------|------|
| `/new-feature` command | The pipeline of record — runs all 11 steps in order (4 phases: plan → build → verify → ship) | Start or resume any feature/fix |
| `/new-idea` command | Scaffolds `ideas/<slug>/` with five docs (README, research, design, plan, tl-dr) + optional `cost.md` | Brainstorm an idea before committing to build it |
| `create-github-issue` skill | Step 4 — draft → confirm → `gh issue create` | Inside the flow |
| `brainstorm` skill | Step 1 — design dialogue (interview, idea-folder ingestion, design-tree rounds, 2-3 approaches) ending in an approved spec under `docs/features/specs/`. Standalone, and invoked by /new-feature step 1 | Inside the flow, or standalone |
| `execute-tasks` skill | Step 5 — task loop, TDD via the `tdd` skill, commit per task. Inline or subagent mode; implement step carries a one-line clean-code pointer (prevention, with review as backstop) | Inside the flow |
| `tdd` skill | Test-first engine for any feature/bugfix — red-green loop, seams, anti-patterns. Standalone, and invoked by execute-tasks per task | Inside the flow, or standalone |
| `test` skill | Step 6 — fresh-subagent test gate: full suite + lint + test-honesty scan; green/red verdict; red returns to execute | Inside the flow, or standalone |
| `review` skill | Step 7 — judgment review via a fresh reviewer subagent: spec covered, obvious issues (bugs, security smells, leftover, naming), maintainability with a clean-code pass (structure, coupling, naming, complexity, duplication, functions, conditionals, comments, code smells, KISS, DRY). Test gate is the test skill (step 6) | Inside the flow, or standalone |
| `doc-fix` skill | Step 8 — pre-PR doc drift scan caused by this run; guided edits, ride in the PR as `docs:` commits | Inside the flow, or standalone |
| `open-pr` skill | Step 9 — opens the PR targeting `dev`: body draft, closing keyword, issue link + issue-body sync, standalone mode. Never merges | Inside the flow, or standalone |
| `commit` skill | Conventional Commits from the diff, **no AI attribution** | Standalone, or per-task in step 5 |
| `document-structure` skill | Builds/updates the target repo's agent docs under `docs/agents/` — tiny index + architecture/dev-ops maps + dynamic concern maps (testing, API, deployment, database, …) | Any repo, on demand |
| `whats-new` skill | Summarizes what's new in a repo: shipped work (git + PRs/issues) + doc-vs-code drift. Never writes a changelog file | Any repo, on demand |
| `tests/check.sh` | The repo's test suite — 9 bash consistency checks run by dev-flow step 6 | Any edit to skills/commands |
| `dev-flow/evals/` | Behavioral evals for the `brainstorm` and `tdd` skills (`claude plugin eval`), run manually after a plugin refresh | After editing a skill |

### Requires: the `superpowers` plugin

`dev-flow` invokes `superpowers:writing-plans`; its brainstorm and TDD loops are dev-flow's own `brainstorm` and `tdd` skills. Install superpowers first.

**One thing to know:** superpowers injects a session-start instruction urging skill use before any response. Inside a dev-flow run, ignore it — dev-flow calls the superpowers skills it needs as sub-steps, and superpowers' defaults (`docs/superpowers/` paths, design-doc commits, "Execution Handoff") **don't apply**. Everything lives under `docs/features/` (gitignored, never committed).

## dev-flow's brainstorm command: `/new-idea`

Scaffolds a structured brainstorm folder for a product or concept:

```
ideas/<slug>/ — README · research · (cost) · design · plan · tl-dr
```

Five self-contained docs by default, no ad-hoc file names; a sixth, `cost.md`, when you opt in — the skill asks up front whether to include cost research (live pricing verification). `cost.md` captures pricing/quotas/limits, and `plan.md` is a milestone-draft plan you can hand straight to `/new-feature` when you're ready to build.

Run `/new-idea <your idea>` in any repo — it asks whether the folder nests by project (ideas repo: `ideas/<project>/<slug>/`) or sits flat (project repo: `ideas/<slug>/`), and whether to include a `cost.md`. Before writing anything it **discusses the idea with you** — one grill round (who's it for, smallest version, hard part), a synthesis, and an explicit go-ahead — so the docs record the settled idea, not your first prompt. It pairs with the pipeline: brainstorm with `/new-idea`, then build with `/new-feature ideas/<slug>` — step 1 ingests the folder's docs as its brief, and the GitHub issue links back to the folder.

## Acknowledgements

`dev-flow` builds on [obra/superpowers](https://github.com/obra/superpowers) (available in Claude Code's official plugin marketplace). Dev-flow reuses one of its skills — `writing-plans` — as a sub-step inside its own pipeline, and adds its own `brainstorm`, `tdd`, `execute-tasks`, `test`, `review`, `doc-fix`, `open-pr`, `create-github-issue`, and `commit` skills so all artifacts stay under `docs/features/` with no `.superpowers/` workspace. Many thanks to the creator and maintainers of superpowers — dev-flow leans on their work for planning.

## Repo layout

```
tests/check.sh                       # the repo's test suite (9 consistency checks)
dev-flow/
├── .claude-plugin/plugin.json      # metadata + peerDependencies.superpowers
├── evals/                           # behavioral evals: brainstorm/, tdd/ (run via claude plugin eval)
├── commands/new-feature.md         # /new-feature — pipeline + hard gate
├── commands/new-idea.md            # /new-idea — scaffold an idea folder (standalone)
└── skills/
    ├── brainstorm/SKILL.md         # step 1 design dialogue → approved spec under docs/features/specs/
    ├── commit/SKILL.md             # Conventional Commits, no AI attribution
    ├── create-github-issue/SKILL.md
    ├── document-structure/SKILL.md # agent-facing doc tree generator (docs/agents/)
    ├── execute-tasks/SKILL.md      # step 5: task loop, TDD via the tdd skill, inline or subagent
    ├── new-idea/SKILL.md           # idea-folder scaffold: fixed slots + optional cost.md + draft plan
    ├── tdd/SKILL.md                # test-first engine (standalone + step 5)
    ├── test/SKILL.md               # step 6: fresh-subagent test gate (suite + lint + test honesty)
    ├── review/SKILL.md             # step 7: pre-PR judgment review via fresh subagent
    ├── doc-fix/SKILL.md            # step 8: pre-PR doc-drift scan for this run's changes
    ├── open-pr/SKILL.md            # step 9: open the PR targeting dev, sync the issue
    └── whats-new/SKILL.md          # "what's new" summary: history + doc-drift check
```

`AGENTS.md` is the agent guidance for this repo; `CLAUDE.md` is a symlink to it so Claude Code, Copilot, and others read the same file.