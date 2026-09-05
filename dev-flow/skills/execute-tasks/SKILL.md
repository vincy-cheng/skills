---
name: execute-tasks
description: Use to execute a dev-flow plan task by task. This is step 5 of the dev-flow workflow — work the plan's tasks with TDD (failing test → implement → green → commit per task), updating the state file as you go. Two modes: inline (default, runs in this session) or subagent (dispatches a fresh implementer subagent per task, for isolation on larger work). Can be invoked standalone if a plan and state file already exist.
---

# Execute tasks

Run the plan's tasks one by one, with TDD. Commit per task. Keep the state file honest. All artifacts stay under `docs/features/`; no `.superpowers/` workspace.

## Gate (dev-flow step 5)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `issue` and set it to `execute` before starting. If not `issue`, stop — a step was skipped — and tell the user which step to run. No state file (standalone) → require a plan path from the user; proceed without the gate.

## What you need before starting

- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — read it once; note its Global Constraints and task list.
- The **state file** — its **Tasks** section mirrors the plan. If it already has `[x]` tasks, resume at the first unchecked one (don't redo done work).
- The repo's test + lint commands (e.g. `flutter test`, `pytest`, `npm test`, `cargo test`). Run them per task and for the final suite.

## Choose a mode

Ask the user which mode (unless they already specified). Ask on **every** entry — including when step 4 was skipped, the plan is small, or the run resumed mid-execute. A small or markdown-only plan is not an exemption:

- **Inline (default)** — you run the TDD loop directly in this session. Simplest; best for small/medium work and when you want to stay in the loop.
- **Subagent** — for each task, dispatch a fresh implementer subagent with only that task's brief, then review its work yourself before committing. Best for larger work where per-task context isolation helps; preserves your session context for coordination.

The rest of this skill has a shared core (state-file updates, stuck handling, after-all-tasks) plus a per-task loop that differs by mode.

## Shared: state-file updates (both modes)

On every task start and complete, and every test run:
- Flip the task's checkbox (`[ ]` → `[x]` on complete); bump **Updated**.
- Refresh **Last verification** with the latest test + lint result. A green run clears any `⚠ test failing` annotation on that task.
- If a task's test is currently red, annotate its line `— ⚠ test failing: <one-line reason>`; clear when green. Leave passing/pending un-annotated.
- **Bump the index file row** — update the feat's row in `docs/features/.feature-states/state.md` with the new **Updated** timestamp and re-sort newest-first. Status stays `execute`; just keep the row's timestamp honest so the index's "current/last run" stays accurate during a long execute.

Never stage or commit `docs/features/` (state, spec, plan, briefs). Stage the task's source files explicitly.

## Inline mode — per-task loop

For each unchecked task, in order:

1. **Read the task** — its `**Files:**` block names what to create/modify and which test covers it.
2. **RED** — write the failing test for the task's behavior. Follow `superpowers:test-driven-development`: one behavior, clear name, real code (no mocks unless unavoidable).
3. **Verify RED** — run the test, confirm it fails for the right reason (feature missing, not a typo). Passes immediately → the test is wrong; fix it before implementing.
4. **GREEN** — implement the minimal code to pass. Don't add behavior the test doesn't require (YAGNI).
5. **Verify GREEN** — run the test, confirm it passes and no other test broke.
6. **Commit** — stage the task's files explicitly, commit via `dev-flow:commit` (Conventional Commits, no AI attribution). Fallback: follow the same rules inline.
7. **Update the state file** (shared rules above).

## Subagent mode — per-task loop

Per-task subagent isolation: the implementer sees only its task, you stay clean for coordination. Artifacts (briefs, reports) go under `docs/features/.sdd/<feat-name>/` — gitignored, same folder as everything else, deleted once the plan lands in git.

For each unchecked task, in order:

1. **Write the brief** to `docs/features/.sdd/<feat-name>/task-N-brief.md` — the task's full text from the plan plus exact values (signatures, test cases, magic strings) the implementer must use verbatim. The brief is the single source of requirements; the dispatch prompt points to it, not the whole plan.
2. **Dispatch the implementer** with: (a) one line on where this task fits; (b) the brief path ("read this first — your requirements"); (c) interfaces/decisions from earlier tasks the brief can't know; (d) a report-file path `docs/features/.sdd/<feat-name>/task-N-report.md` and the report contract (full report written there; returns only status, commits, one-line test summary, concerns). Specify the model explicitly — cheap for mechanical/well-specified tasks, standard for multi-file integration. **Never dispatch more than one implementer in parallel** (conflicts).
3. **Handle the report:**
   - **DONE** → review (step 4).
   - **DONE_WITH_CONCERNS** → read concerns; address correctness/scope ones before review, note observations and proceed.
   - **NEEDS_CONTEXT** → provide the missing context, re-dispatch.
   - **BLOCKED** → assess: context problem → re-dispatch with more context; needs more reasoning → more capable model; task too large → split it; plan wrong → surface to the user.
4. **Review the task yourself** — you hold cross-task context the implementer lacks. Read the diff (`git diff <BASE>..HEAD`, where BASE is the commit before the implementer ran). Check: spec/task compliance, test honesty (asserts real behavior, watched it fail), no leftover/debug, no scope creep. This is a single self-review by you, not a subagent — lighter than SDD's two-stage reviewer. If clean → step 5. If not → send the findings back to the implementer (re-dispatch with the open findings; up to 3 rounds, then a fresh more-capable implementer; after 5, adjudicate: park or surface as BLOCKED).
5. **Commit** — stage the task's files explicitly, commit via `dev-flow:commit`. (If the implementer already committed with a clean message that follows the rules, you may keep it; otherwise amend/recommit.)
6. **Update the state file** (shared rules above).

Keep your own context clean: everything you paste into a dispatch and everything a subagent prints back stays resident. Hand artifacts over as files (brief, report), not inline dumps.

## When a task gets stuck (both modes)

- **Test won't go green after a real attempt**: stop, don't push through. Re-read the task and relevant code. If the plan is wrong (the task as written can't be satisfied), surface it to the user — that's a plan defect, not an implementation problem.
- **Scope creeps into the task**: if implementing reveals work the plan didn't list, note it and ask whether to add a task or defer. Don't silently expand the commit.
- **A task depends on a later task's symbol**: the plan is mis-ordered. Surface it; reorder in the plan rather than jumping ahead.

## After all tasks

- Run the **full test + lint suite** one more time. Update **Last verification** — this is the green signal the next step (review → PR) relies on.
- In subagent mode: delete `docs/features/.sdd/<feat-name>/` — the git history is the record now.
- Do **not** open the PR here — that's dev-flow step 6. Do **not** invoke `superpowers:finishing-a-development-branch` — this workflow's merge is manual (step 7), not a local merge.
- Hand back to `/new-feature`: it invokes `dev-flow:review` next, then advances to step 6.

## What not to do

- **No `git add -A` / `git add .`** — stage the task's files explicitly.
- **No staging or committing `docs/features/`** — state, spec, plan, and subagent briefs/reports are gitignored; if untracked shows, gitignore drifted — fix the ignore, don't commit.
- **No skipping verify-RED** — if you didn't watch the test fail (inline) or the implementer's report doesn't show it failing first (subagent), you don't know it tests the right thing.
- **No committing a red task** — tests must be green before the commit.
- **No pushing** — this skill commits only. Push is step 6.
- **No parallel implementers** (subagent mode) — one task at a time; they'd conflict.