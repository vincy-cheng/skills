# skills

AI coding-agent plugins published from this repo. Each top-level directory is one Claude Code plugin.

## Plugins

### `dev-flow`

Drives a feature **or fix** end-to-end: brainstorm → spec → plan → create GitHub issue → execute (TDD) → review → PR → manual merge. Keeps gitignored state files so work resumes across sessions, and uses a **hard gate** so invoked sub-skills can't skip or reorder steps. An **index file** (`docs/features/.feature-states/state.md`) mirrors all runs — open it to see the current/last task at a glance.

Provides:
- `/new-feature` command — the pipeline of record.
- `create-github-issue` skill — step 4 (draft → confirm → `gh issue create`).
- `execute-tasks` skill — step 5: own TDD loop, progress in the state file, commit per task. Two modes: inline (default) or subagent (fresh implementer per task for isolation). No `.superpowers/` workspace — all under `docs/features/`.
- `review` skill — step 5.5: pre-PR self-review gate (test green, spec coverage, obvious issues). Also runs standalone.
- `commit` skill — Conventional Commits messages from the diff, with **no AI attribution** in the message or trailers. Runs standalone or per-task during step 5.

#### Requires: the `superpowers` plugin

`dev-flow` invokes `superpowers:brainstorming`, `superpowers:writing-plans`, and `superpowers:test-driven-development`. Install superpowers first.

## Install

Install superpowers, then dev-flow:

```
/plugin install superpowers
/plugin install vincy-cheng/skills
```

Or, from a git URL (works for private repos too — your git/SSH auth provides access):

```
claude plugin install https://github.com/vincy-cheng/skills.git
```

After installing, run `/new-feature <your idea>` in any repo that uses the `gh` CLI. Run `/new-feature` with no args (or `/new-feature resume`) to **resume** — it reads the index file, lists your runs by last-updated, and continues the newest active one, so you don't have to remember the task name.

### Private vs public

This repo can be **private** — an installing account only needs git read access (GitHub collaborator invite, SSH key, or a PAT). No need to make it public to share with specific accounts. Make it public if you want anyone to install it without granting access.

## Repo layout

```
dev-flow/
├── .claude-plugin/plugin.json      # metadata + peerDependencies.superpowers
├── commands/new-feature.md         # /new-feature — pipeline + hard gate
└── skills/
    ├── commit/SKILL.md             # Conventional Commits, no AI attribution
    ├── create-github-issue/SKILL.md
    ├── execute-tasks/SKILL.md      # step 5: inline TDD loop
    └── review/SKILL.md             # step 5.5: pre-PR self-review gate
```

`AGENTS.md` is the agent guidance for this repo; `CLAUDE.md` is a symlink to it so Claude Code, Copilot, and others read the same file.