---
name: whats-new
description: Use to summarize what's new in a repo — recent shipped work AND current codebase state vs. its docs. Triggers on "what's new", "what changed recently", "summarize recent work", "catch me up on this repo". Returns a view (nothing written): history from git log + gh PRs/issues, plus a doc-drift check (do the docs match the code). Not a changelog file — an on-demand summary.
---

# What's new

Answer "what's new in this repo?" as a compact summary. Two sources, one output:

1. **History** — what *happened*: git log + merged PRs + closed issues in a window.
2. **State** — what *is*: does the codebase match what its docs claim?

Never write or maintain a record — git history is the source of truth; this skill only summarizes it. If asked to maintain a changelog file, decline and explain why (duplicated git log drifts).

## Phase 1 — Gather history

- **Window:** last tag if the repo tags (`git describe --tags --abbrev=0`); else last 14 days; the user may name a date, branch, or range.
- **Commits:** `git log` in the window — group mentally by feature/PR, not per commit.
- **PRs/issues:** `gh pr list --state merged` / `gh issue list --state closed` in the window (`--limit 30` is plenty). Pair commits to PRs when possible; PR titles carry the "why" that commit messages lack. If `gh` fails or the repo has no remote, summarize from git alone and say so.
- **Doc commits:** collect commits touching `README.md`, `AGENTS.md`/`CLAUDE.md`, `docs/` separately — they feed the *Docs updated* section.

## Phase 2 — Check state (doc drift)

Spot-check the repo's doc claims against the code — the part a raw git summary misses:

- Read `README.md`, `AGENTS.md`/`CLAUDE.md`, and `docs/` (including `docs/agents/` if present).
- Verify the checkable claims: do named files/modules/commands exist? Do documented run/build/test commands match config (package.json, Makefile, etc.)?
- Look for the undocumented: new modules, commands, or conventions that exist in code but no doc mentions.
- Keep this a **spot-check** (minutes, not a full audit). If `dev-flow:agent-docs` generated the `docs/agents/` tree, its `last updated` footers show which maps might be stale.

## Phase 3 — Summarize

Return a compact summary, newest first, grouped by feature/PR — not a commit dump. Sections, skipping any that are empty:

- **Shipped** — merged features/fixes, one line each: what + why (from PR/issue), with `#number` references.
- **Docs updated** — doc changes in the window, one line each.
- **Doc drift found** — claims that don't match the code (phase 2 findings), each with the doc location and the mismatch. Suggest `agent-docs` update mode when the `docs/agents/` tree is the stale surface.
- **Open threads** — open PRs, unmerged branches worth knowing about.

Plain declarative sentences; link numbers (`#12`) where the user can act on them. End with the window used (e.g. "since tag v2.3.0 / last 14 days") so the summary is reproducible.

## What not to do

- **Don't write files** — no changelog, no notes; this is a view, not a record.
- **Don't dump raw git log** — group and summarize; the value is compression.
- **Don't deep-audit** — the drift check is a spot-check; agent-docs owns full doc generation.
- **Don't invent** — a section with no findings is omitted, not padded.