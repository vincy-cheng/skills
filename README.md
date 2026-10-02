# skills

AI coding-agent plugins published from this repo. `dev-flow` supports Claude Code and Codex through host-specific plugin metadata and orchestrators, with shared standalone skills.

## Install

```
/plugin marketplace add vincy-cheng/skills
/plugin install dev-flow@vincy-skills
```

Alternatively, install dev-flow directly from the git URL:

```
claude plugin install https://github.com/vincy-cheng/skills.git
```

Then run `/new-feature <your idea>` in any repo with the `gh` CLI. Run `/new-feature` with no args to **resume** — it finds your last run for you.

The same install also gives you `/new-idea` — dev-flow's structured brainstorm command (see below).

### Install in Codex

Add the marketplace straight from GitHub — no clone needed:

```sh
codex plugin marketplace add vincy-cheng/skills
```

Restart the Codex desktop app, open the **Plugins Directory**, choose **Vincy Skills (Codex)**, and install `dev-flow`. The package includes all shared skills and the `new-feature` workflow skill. To start a feature, invoke `$dev-flow:new-feature` with your brief; invoke it without a new brief to resume the latest active run.

Alternatively, from this repository's root (local checkout):

```sh
codex plugin marketplace add .
```

After updating this checkout, refresh the marketplace with `codex plugin marketplace upgrade vincy-skills`, then restart Codex so the installed copy picks up the changes.

## Plugin: `dev-flow`

Drives a feat **or fix** end-to-end:

```
brainstorm → spec → plan → issue → execute (TDD) → test → review → doc-fix → PR → merge → close-out
```

Three guarantees:
- **Hard gate** — sub-skills can't skip or reorder steps.
- **Resumable** — gitignored state files + an index file (`docs/features/.feature-states/.state.md`) track every run.
- **Local artifacts** — specs/plans/state live under `docs/features/`, never committed.

### What it provides

| Piece | What it does | When |
|-------|--------------|------|
| `/new-feature` command | Claude Code pipeline of record — runs all 11 steps in order (4 phases: plan → build → verify → ship) | Start or resume any feature/fix in Claude Code |
| `new-feature` skill | Codex version of the same 11-step orchestrator and hard gate | `$dev-flow:new-feature` in Codex |
| `/new-idea` command | Scaffolds `ideas/<slug>/` with five docs (README, research, design, plan, tl-dr) + optional `cost.md` | Brainstorm an idea before committing to build it |
| `create-github-issue` skill | Step 4 — draft → confirm → `gh issue create` | Inside the flow |
| `plan` skill | Step 3 — contract-first plan engine: overview, Global Constraints, Flow Chart (Mermaid), File Structure, bite-sized TDD-shaped tasks ending in an approved plan under `docs/features/plans/`. Standalone, and invoked by /new-feature step 3 | Inside the flow, or standalone |
| `brainstorm` skill | Step 1 — design dialogue (interview, idea-folder ingestion, design-tree dialogue one question at a time, 2-3 approaches) ending in an approved spec under `docs/features/specs/`. Standalone, and invoked by /new-feature step 1 | Inside the flow, or standalone |
| `execute-tasks` skill | Step 5 — task loop, TDD via the `tdd` skill, commit per task. Inline or subagent mode; implement step carries a one-line clean-code pointer (prevention, with review as backstop) | Inside the flow |
| `tdd` skill | Test-first engine for any feature/bugfix — red-green loop, seams, anti-patterns. Standalone, and invoked by execute-tasks per task | Inside the flow, or standalone |
| `test` skill | Step 6 — fresh-subagent test gate: full suite + lint + test-honesty scan; green/red verdict; red returns to execute | Inside the flow, or standalone |
| `review` skill | Step 7 — judgment review via a fresh reviewer subagent: spec covered, obvious issues (bugs, security smells, leftover, naming), maintainability with a clean-code pass (structure, coupling, naming, complexity, duplication, functions, conditionals, comments, code smells, KISS, DRY). Test gate is the test skill (step 6) | Inside the flow, or standalone |
| `doc-fix` skill | Step 8 — pre-PR doc drift scan caused by this run; guided edits, ride in the PR as `docs:` commits | Inside the flow, or standalone |
| `open-pr` skill | Step 9 — opens the PR targeting `dev`: body draft, closing keyword, issue link + issue-body sync, standalone mode. Never merges | Inside the flow, or standalone |
| `commit` skill | Conventional Commits from the diff, **no AI attribution** | Standalone, or per-task in step 5 |
| `document-structure` skill | Builds/updates the target repo's agent docs under `docs/agents/` — tiny index + architecture/dev-ops maps + dynamic concern maps (testing, API, deployment, database, …) | Any repo, on demand |
| `whats-new` skill | Summarizes what's new in a repo: shipped work (git + PRs/issues) + doc-vs-code drift. Never writes a changelog file | Any repo, on demand |
| `tests/check.sh` | The repo's test suite — 14 bash consistency checks run by dev-flow step 6 | Any edit to skills/commands |
| `dev-flow/evals/` | Behavioral evals for the `brainstorm`, `plan`, and `tdd` skills (`claude plugin eval`), run manually after a plugin refresh | After editing a skill |

## dev-flow is fully self-contained

Every step's engine is dev-flow's own skill — brainstorm, plan, tdd, execute-tasks, test, review, doc-fix, open-pr, create-github-issue, commit — no external plugin dependencies. All artifacts live under `docs/features/` (gitignored, never committed).

## dev-flow's brainstorm command: `/new-idea`

Scaffolds a structured brainstorm folder for a product or concept:

```
ideas/<slug>/ — README · research · (cost) · design · plan · tl-dr
```

Five self-contained docs by default, no ad-hoc file names; a sixth, `cost.md`, when you opt in — the skill asks up front whether to include cost research (live pricing verification). `cost.md` captures pricing/quotas/limits, and `plan.md` is a milestone-draft plan you can hand straight to `/new-feature` when you're ready to build.

Run `/new-idea <your idea>` in any repo — it asks whether the folder nests by project (ideas repo: `ideas/<project>/<slug>/`) or sits flat (project repo: `ideas/<slug>/`), and whether to include a `cost.md`. Before writing anything it **discusses the idea with you** — one grill round (who's it for, smallest version, hard part), a synthesis, and an explicit go-ahead — so the docs record the settled idea, not your first prompt. It pairs with the pipeline: brainstorm with `/new-idea`, then build with `/new-feature ideas/<slug>` — step 1 ingests the folder's docs as its brief, and the GitHub issue links back to the folder.

## Acknowledgements

`dev-flow`'s workflow shape — brainstorm → spec → plan → issue → execute → review → merge — and its early planning engine were inspired by [obra/superpowers](https://github.com/obra/superpowers). Dev-flow has since replaced every borrowed piece with its own skills (`brainstorm`, `plan`, `tdd`, `execute-tasks`, `test`, `review`, `doc-fix`, `open-pr`, `create-github-issue`, `commit`) so all artifacts stay under `docs/features/`. Many thanks to the creator and maintainers of superpowers.

The `tdd` skill's **seams** concept (test at public boundaries, never internals) comes from Kent Beck's *Test-Driven Development: By Example*, encountered via Matt Pocock's skill collections ([mattpocock-skills](https://github.com/mattpocock/skills)).

The `review` skill's clean-code pass is distilled from Robert C. Martin's *Clean Code* (via [wojteklu's clean-code checklist](https://gist.github.com/wojteklu/73c6914cc446146b8b533c0988cf8d29) and the r/cleancode community guide). Many thanks to all of them.

## Repo layout

```
tests/check.sh                       # the repo's test suite (14 consistency checks)
.agents/plugins/marketplace.json    # repository-local Codex plugin source
dev-flow/
├── plugin.json                      # portable Codex plugin manifest
├── .claude-plugin/plugin.json      # metadata (fully self-contained — no peer dependencies)
├── evals/                           # behavioral evals: brainstorm/, plan/, tdd/ (run via claude plugin eval)
├── commands/new-feature.md         # /new-feature — pipeline + hard gate
├── commands/new-idea.md            # /new-idea — scaffold an idea folder (standalone)
└── skills/
    ├── brainstorm/SKILL.md         # step 1 design dialogue → approved spec under docs/features/specs/
    ├── commit/SKILL.md             # Conventional Commits, no AI attribution
    ├── create-github-issue/SKILL.md
    ├── document-structure/SKILL.md # agent-facing doc tree generator (docs/agents/)
    ├── execute-tasks/SKILL.md      # step 5: task loop, TDD via the tdd skill, inline or subagent
    ├── new-idea/SKILL.md           # idea-folder scaffold: fixed slots + optional cost.md + draft plan
    ├── new-feature/SKILL.md        # Codex orchestrator; mirrors commands/new-feature.md
    ├── plan/SKILL.md               # step 3 contract-first plan engine → approved plan under docs/features/plans/
    ├── tdd/SKILL.md                # test-first engine (standalone + step 5)
    ├── test/SKILL.md               # step 6: fresh-subagent test gate (suite + lint + test honesty)
    ├── review/SKILL.md             # step 7: pre-PR judgment review via fresh subagent
    ├── doc-fix/SKILL.md            # step 8: pre-PR doc-drift scan for this run's changes
    ├── open-pr/SKILL.md            # step 9: open the PR targeting dev, sync the issue
    └── whats-new/SKILL.md          # "what's new" summary: history + doc-drift check
```

`AGENTS.md` is the agent guidance for this repo; `CLAUDE.md` is a symlink to it so Claude Code, Copilot, and others read the same file.
