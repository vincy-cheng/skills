---
name: doc-fix
description: Use to fix doc drift caused by the current run before opening its PR — dev-flow step 8. Scans this plugin's docs and the target repo's docs for text the run's changes just invalidated (behavior described the old way, a new convention not documented), shows the proposed edits for user confirmation, then commits them as docs: commits riding in the PR. If the target repo has no docs/agents/ tree, generates one via document-structure (skip if declined). Also runs standalone on any branch ("fix the doc drift", "update the docs for this branch") with the same drift-scan against the branch's diff. No drift → honest no-op pass. Not a general doc audit — only drift this run caused.
---

# Doc-fix

Pre-PR doc gate: the work is done and reviewed; before the PR opens, close the loop on docs the run itself may have invalidated. Find doc drift caused by *this* run — not a general audit.

## Gate (dev-flow, step 8)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `review` before starting, and set it to `doc-fix` before scanning. Don't advance further — step 9 (open PR) sets `pr-review`. If the status isn't `review`, stop — a step was skipped — and tell the user which step to run. No state file (standalone) → see *Standalone mode* below.

## What to scan, in order of drift likelihood

1. **This plugin's docs** — `AGENTS.md`/`CLAUDE.md`, `README.md`, and any `skills/*/SKILL.md` touched by the work. Did the run change behavior a doc still describes the old way? Did a new convention emerge (e.g. a new state-file column this run added)?
2. **The target repo's docs** — `AGENTS.md`/`README`/arch docs in the repo the feature landed in. Did the change add a new module, command, or convention the docs should mention?

The scan scope is the **run's diff** (`git diff <base>...HEAD`), not the whole repo — drift caused by *this* run. If a piece of drift predates the run, note it to the user but don't fix it here; that's the `dev-flow:whats-new`/`document-structure` territory.

## Missing docs/agents/ tree

If the target repo has no `docs/agents/` directory at all, don't treat that as "no drift" — generate the tree once via `dev-flow:document-structure` (index + core maps; deep-detail files optional). The tree ships in this run's PR as `docs:` commits, so the repo's agent-facing docs exist from the first PR onward. Still guided: show the proposed files before writing, and skip the generation if the user declines (then it's an honest no-op for them to run standalone later). If a tree already exists, do not regenerate it — treat it as drift territory only.

## Rules

- **Show the user the proposed doc edits before applying** — guided, not fire-and-forget.
- **Commit doc updates as `docs:`-type commits** — a run's own drift ships in the same PR as the code, not after merge.
- **Never commit `docs/features/`** (spec, plan, state, index) — still gitignored.
- **No drift found** → quick no-op pass; say so plainly and hand back to advance. Don't invent edits.

## Verdict

- Drift found and fixable → show the proposed edits; on confirmation, apply and commit as `docs:`; hand back to advance to step 9.
- Drift reveals a deeper code issue → **STOP**; don't open a PR with known-bad docs (mirrors review's red). Surface to the user; return to step 5 if the drift comes from a real code issue.
- No drift → no-op pass, advance.

## Standalone mode (outside dev-flow)

When invoked without a state file: ask for the base branch (or infer from `git merge-base`), diff against it, and run the same drift scan — "what did this branch change that existing docs still describe the old way?" Show proposed edits for confirmation before applying; commit them as `docs:` on the same branch. No drift → say so plainly and commit nothing.

## What not to do

- **Don't fix drift you didn't cause** — pre-existing stale docs go to `whats-new`/`document-structure`, not this run's PR.
- **Don't edit docs without showing the user first** — guided, always.
- **Don't commit `docs/features/`** — the commit guard applies to `docs:` commits too.
- **Don't turn it into a general audit** — this run's diff is the scope. A full sweep belongs to `document-structure`.
- **Don't open the PR** — that's step 9. Hand back with a verdict.