---
name: bootstrap
description: Use to prepare a repo for dev-flow in one pass — gitignore for the state folder, gh auth check, branch config (main + dev branch names persisted to .dev-flow/config.json), and agent docs via the document-structure engine. Triggers on "bootstrap this repo", "set up this repo for dev-flow", "prepare this repo", or a repo missing dev-flow setup that keeps hitting mid-flow interruptions (missing dev branch, unignored state files, no agent docs). Standalone in any repo; not part of the dev-flow step sequence and never gated by the state file. Doubles as a health check — re-runs are green no-ops.
---

# Bootstrap

Prepare the **current** repo for dev-flow use in one invocation. Five components, run in order, each independently idempotent: report **already ready / partial / missing** per component, act only on confirmation. **Never silently overwrite** — every mutation is presented before being applied.

Bootstrap is **standalone** — not a dev-flow step, never gated by the state file. Re-invocation is a green no-op ("already initialized") per component; the skill doubles as a health check. **Bootstrap never commits** — every change is left uncommitted in the working tree and reported in the closing checklist; the user reviews and commits.

## 0. Precheck — git repo

`git rev-parse --is-inside-work-tree` — fails → report "not a git repo" and **stop** (components 2–5 all need git; running on would cascade failures). Do not run the other components.

## Components

### 1. Gitignore

```bash
git check-ignore -q docs/features/ || echo "NOT_IGNORED"
```

- `NOT_IGNORED` → show the user the proposed append (one line: `docs/features/`) and on confirmation append to `.gitignore` (create the file if absent).
- Already ignored → report "already ignored"; no append.
- `docs/features/` **already tracked** (`git ls-files docs/features/` non-empty) → surface it and **stop this component** — never silently `git rm`; ask the user how to proceed.
- A broader pattern already matching → `git check-ignore` is the truth; no append needed; report as already covered.

### 2. gh auth check

- `gh auth status` succeeds → report OK.
- Fails (not installed / not authenticated) → **yellow warning with the fix instructions** (`gh auth login`), then **continue** — never a gate. Local-only users must not be blocked.

### 3. Branch config

**Wiring:** `.dev-flow/config.json` seeds the state file's Base/Target at `new-feature` step 1; every downstream skill reads the state file's branch fields — never a literal branch name.

- Detect the default branch: `git symbolic-ref refs/remotes/origin/HEAD`; fall back to `gh repo view --json defaultBranchRef`; fall back to the current branch. Undetectable → ask the user for the main branch name.
- Ask the user for both names (each with its default offered): **main branch** (default: detected value) and **dev branch** (default: `dev`, never hard-gated — `develop`, `trunk`, anything).
- **Single-branch repos:** if the user's dev branch == main branch, warn that `open-pr` refuses `main` as a PR target and resolve first: a separate dev branch, or main-only mode (`new-feature`'s existing main-only handling — base/target both the main branch; such repos don't use open-pr). Write the config only after this is resolved.
- Config file `.dev-flow/config.json` (repo root):
  ```json
  { "main_branch": "<main>", "dev_branch": "<dev>" }
  ```
  `main_branch` documents the main branch for health-check reporting; `dev_branch` is the consumed key (read by `new-feature` step 1).
- Dev branch exists (the chosen name) → report "already exists".
- Dev branch missing → **offer**: create it off the main branch (locally + push, or locally only — ask which). Never create silently.
- Config exists and matches → report. Names differ → show the diff and ask whether to update.

### 4 + 5. AGENTS.md entry point + docs/agents/ tree — delegated

`docs/agents/INDEX.md` exists and `AGENTS.md` is correctly paired with a `CLAUDE.md` symlink → report "already set up"; touch nothing.

Either or both missing → make **one ask**: offer to run the `dev-flow:document-structure` skill. One invocation brings up the whole agent-facing surface — the progressive-disclosure tree under `docs/agents/` **and** the entry-point pair (its AGENTS.md entry-point rule: `AGENTS.md` as a real file — minimal skeleton only when created from nothing — with `CLAUDE.md` as a symlink to it). A decline is a normal outcome: skip both, report it, move on. Bootstrap itself never writes AGENTS.md, CLAUDE.md, or anything under `docs/agents/` — the engine owns the whole surface.

## Output format

A closing checklist, one line per component:

```
✓ gitignore: docs/features/ ignored
✓ gh: authenticated
❓ dev branch: develop missing — create off main?   (asked / offered)
+ config: .dev-flow/config.json written
− docs/agents/ + AGENTS.md: skipped (declined)
```

Glyphs: ✓ already/just-done · ⚠ warned · ❓ asked · + created · − declined · ✗ failed (with reason). A re-run where nothing was asked or changed is the green no-op: all ✓.

## Error handling

- Each component is an atomic single action — no retry logic.
- A failing git/gh command reports the failure and moves to the next component; the run does not abort mid-way (exception: the not-a-git-repo precheck above — that stops the run).
- The only mutation surface: `.gitignore` append, `.dev-flow/config.json` write, branch creation, document-structure invocation — all gated on user confirmation, none committed by bootstrap.

## Standalone mode

Any repo, no state file, no gate. The repo's existing dev-flow runs (if any) are unaffected: bootstrap only adds or reports, never edits skill behavior.