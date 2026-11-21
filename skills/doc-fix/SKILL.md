---
name: doc-fix
description: Use during dev-flow build when an implementation task reveals a known documentation edit, with explicit in-flow context and user confirmation; or standalone to fix doc drift on a branch. In-flow edits stay in the task commit. Standalone edits keep the guided docs commit. Not a general doc audit — only drift this run caused.
---

# Doc-fix

## Output style

Before writing responses or human-readable files, load [`references/output-style.md`](../../references/output-style.md), resolving the link from this skill file’s host-provided base directory (two levels up to the plugin root), not the working directory. Pass its actual contents to every subagent you dispatch, including isolated reviewers. User requirements and specific output contracts take precedence.

Guided documentation repair for behavior or conventions changed by this run. Dev-flow invokes this skill during build only with explicit in-flow context. Standalone use remains available outside an active run associated with the work, even when the state directory contains historical or unrelated run files.

## In-flow build gate

When this documentation work belongs to an active dev-flow run, require explicit in-flow context from `execute-tasks` containing the associated state-file path, current task and its authorization, affected documentation paths, and relevant diff. Verify **Goal status** is `execute`. Missing context or any other status for that associated active run → stop and return to `/new-feature`; never fall back to standalone mode. State-file presence alone does not establish association: a historical `done` state or a state file for another feature neither authorizes in-flow mode nor blocks standalone mode. Do not change Goal status, the index row, **Updated**, or **Status since**.

Scope the scan to the task's planned documentation and the current task diff/worktree. Show proposed edits and wait for the user's confirmation before applying them. Keep the changed docs in the current task's verification and commit. Return changed paths, checks to rerun, and unresolved drift to `execute-tasks`; do not commit in this mode.

## What to scan, in order of drift likelihood

1. **This plugin's docs** — `AGENTS.md`/`CLAUDE.md`, `README.md`, and any `skills/*/SKILL.md` touched by the work. Did the run change behavior a doc still describes the old way? Did a new convention emerge (e.g. a new state-file column this run added)?
2. **The target repo's docs** — `AGENTS.md`/`README`/arch docs in the repo the feature landed in. Did the change add a new module, command, or convention the docs should mention?

In-flow scan scope is the task's planned docs plus its diff and relevant working-tree changes. Standalone scope is the run's diff (`git diff <base>...HEAD`), not the whole repo. In both modes, fix only drift caused by this run. If drift predates the run, note it but leave it to `dev-flow:whats-new` or `document-structure`.

## Missing docs/agents/ tree

If the target repo has no `docs/agents/` directory, do not silently add one in build. Generate it only when the current task authorizes it and the user confirms the proposed files; otherwise report the gap and ask whether to expand scope. Standalone mode may use `dev-flow:document-structure` with the same guided confirmation. If a tree already exists, do not regenerate it — treat relevant files as drift territory only.

## Rules

- **Show the user the proposed doc edits before applying** — guided, not fire-and-forget.
- **In-flow build mode** applies only after the task's doc edits are confirmed and does not commit; `execute-tasks` verifies and commits the docs with that task.
- **Standalone mode** commits confirmed doc updates as `docs:`-type commits on the same branch.
- **Never commit `docs/features/`** (spec, plan, state, index) — still gitignored.
- **No drift found** → say so plainly. In-flow mode returns to `execute-tasks`; standalone mode ends with no commit. Don't invent edits.
- In-flow edits remain part of the task's changes and verification. The task commit becomes the build artifact; test and review run afterward against it.

## Verdict

- In-flow build mode: drift found and fixable → show the proposed edits; on confirmation, apply and hand back to `execute-tasks` for task verification and commit.
- Standalone mode: drift found and fixable → show the proposed edits; on confirmation, apply and commit as `docs:`.
- Drift reveals a deeper code issue → **STOP**; return the issue to `execute-tasks` and keep the run at `execute`.
- No drift → no-op; hand back to the current caller.

## Standalone mode (outside an active dev-flow run associated with this work)

When invoked outside an active dev-flow run associated with this work, ask for the base branch (or infer from `git merge-base`), diff against it, and run the same drift scan — "what did this branch change that existing docs still describe the old way?" Show proposed edits for confirmation before applying; commit confirmed edits as `docs:` on the same branch. Historical `done` states and state files for other features do not switch this invocation into in-flow mode or block standalone use. No drift → say so plainly and commit nothing.

## What not to do

- **Don't fix drift you didn't cause** — pre-existing stale docs go to `whats-new`/`document-structure`, not this run's PR.
- **Don't edit docs without showing the user first** — guided, always.
- **Don't commit `docs/features/`** — the commit guard applies to `docs:` commits too.
- **Don't use an in-flow call as standalone** — an active run requires the explicit `execute-tasks` context and `execute` status.
- **Don't turn it into a general audit** — this run's diff is the scope. A full sweep belongs to `document-structure`.
- **Don't open the PR** — that's step 9. Hand back with a verdict.
