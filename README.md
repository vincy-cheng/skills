# skills

AI coding-agent plugins published from this repo. Each top-level directory is one Claude Code plugin.

## Plugins

### `dev-flow`

Drives a feature **or fix** end-to-end: brainstorm → spec → plan → create GitHub issue → execute (TDD) → PR → manual merge. Keeps a gitignored state file so work resumes across sessions, and uses a **hard gate** so invoked sub-skills can't skip or reorder steps.

Provides:
- `/new-feature` command — the 7-step pipeline of record.
- `create-github-issue` skill — step 4 (draft → confirm → `gh issue create`).
- `commit` skill — Conventional Commits messages from the diff, with **no AI attribution** in the message or trailers. Runs standalone or per-task during step 5.

#### Requires: the `superpowers` plugin

`dev-flow` invokes `superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:subagent-driven-development`, `superpowers:test-driven-development`, and `superpowers:finishing-a-development-branch`. Install superpowers first.

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

After installing, run `/new-feature <your idea>` in any repo that uses the `gh` CLI.

### Private vs public

This repo can be **private** — an installing account only needs git read access (GitHub collaborator invite, SSH key, or a PAT). No need to make it public to share with specific accounts. Make it public if you want anyone to install it without granting access.

## Repo layout

```
dev-flow/
├── .claude-plugin/plugin.json   # metadata + peerDependencies.superpowers
├── commands/new-feature.md      # /new-feature — the 7-step pipeline + hard gate
└── skills/
    └── create-github-issue/SKILL.md
```

`AGENTS.md` is the agent guidance for this repo; `CLAUDE.md` is a symlink to it so Claude Code, Copilot, and others read the same file.