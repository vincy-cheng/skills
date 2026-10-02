---
name: execute-tasks
description: >-
  Use to execute a dev-flow plan task by task. This is step 5 of the dev-flow workflow — work the
  plan's tasks with TDD (failing test → implement → green → commit per task), updating the state file
  as you go. Two modes: inline (default, runs in this session) or subagent (dispatches a fresh
  implementer subagent per task, for isolation on larger work). Can be invoked standalone if a plan
  and state file already exist.
---

# Execute tasks

Run the plan's tasks one by one, with TDD. Commit per task. Keep the state file honest. All artifacts stay under `docs/features/`; no `.superpowers/` workspace.

## Gate (dev-flow step 5)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `issue` and set it to `execute` before starting. If not `issue`, stop — a step was skipped — and tell the user which step to run.

Then **verify the branch before any work**: the current branch (`git branch --show-current`) must equal the state file's **Base branch** (the `feat/<n>-<name>` / `fix/<n>-<name>` branch step 4 created). Mismatch → stop and ask — don't switch or commit anything yourself; the user may have uncommitted work where they are. Executing on the wrong branch commits another branch's history into the run — this check is cheap and prevents the most damaging silent mistake in the flow. No state file (standalone) → require a plan path from the user; proceed without the gate.

## What you need before starting

- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — read it once; note its Global Constraints and task list.
- The **state file** — its **Tasks** section mirrors the plan. If it already has `[x]` tasks, resume at the first unchecked one (don't redo done work).
- The repo's test + lint commands (e.g. `flutter test`, `pytest`, `npm test`, `cargo test`). Run them per task and for the final suite.

## Choose a mode

Read the plan's signal first, **recommend** a mode with one line of reasoning, then offer the user an override. Don't punt the choice unguided — but still ask on **every** entry (including when step 4 was skipped, the plan is small, or the run resumed mid-execute; a small or markdown-only plan is not an exemption). Lead with the recommendation, not a bare "which mode?".

Signal to read: **task count**, **file spread** (how many files the tasks touch), **task coupling** (do later tasks depend on earlier tasks' exact symbols/wording?).

- **Inline** when ≤3 tasks, docs-only/markdown edits (no test cycle to isolate), or tightly-coupled tasks (subagent isolation *hurts* here); simplest, and you stay in the loop.
- **Subagent** when ≥5 tasks, many files, or genuinely independent tasks (per-task context isolation is a feature). For each task, dispatch a fresh implementer with only that task's brief, then review its work yourself before committing.
- **Ambiguous middle** → recommend **inline** (staying in the loop wins when the signal is mixed) but name the tradeoff: subagent buys isolation at the cost of context handoff overhead.

Example: "4 tasks, all in `new-feature.md` (one file, tightly coupled — each edit builds on the prior's wording) → inline. Override to subagent?"

**Implementer model (subagent mode only).** When the user picks **subagent mode**, also ask the **Implementer model** (default: same as the current session) and write it to the state file's **Model picks** block — one pick for all per-task implementer subagents. Inline mode → write `_(inline — not asked)_` to the **Model picks** block. This is the Build phase's one model pick; the Verify phase's **Verifier model** is asked separately at step 6.

The rest of this skill has a shared core (state-file updates, stuck handling, after-all-tasks) plus a per-task loop that differs by mode.

## Shared: state-file updates (both modes)

On every task start and complete, and every test run:
- Flip the task's checkbox (`[ ]` → `[x]` on complete); bump **Updated**.
- Refresh **Last verification** with the latest test + lint result. A green run clears any `⚠ test failing` annotation on that task.
- If a task's test is currently red, annotate its line `— ⚠ test failing: <one-line reason>`; clear when green. Leave passing/pending un-annotated.
- **Bump the index file row** — update the feat's row in `docs/features/.feature-states/.state.md` with the new **Updated** timestamp and re-sort newest-first. Status stays `execute`; just keep the row's timestamp honest so the index's "current/last run" stays accurate during a long execute.

Never stage or commit `docs/features/` (state, spec, plan, briefs). Stage the task's source files explicitly.

## Inline mode — per-task loop

For each unchecked task, in order:

1. **Read the task** — its `**Files:**` block names what to create/modify and which test covers it.
2. **RED** — write the failing test for the task's behavior. Follow `dev-flow:tdd`: one behavior, clear name, test at a public seam with real code (no mocks unless unavoidable).
3. **Verify RED** — run the test, confirm it fails for the right reason (feature missing, not a typo). Passes immediately → the test is wrong; fix it before implementing.
4. **GREEN** — implement the minimal code to pass. Don't add behavior the test doesn't require (YAGNI). Keep it clean as you write — small single-purpose functions, descriptive names, no magic numbers; `dev-flow:review`'s clean-code pass (step 7) is the backstop checklist, not a license to defer.
5. **Verify GREEN** — run the test, confirm it passes and no other test broke.
6. **Commit** — stage the task's files explicitly, commit via `dev-flow:commit` (Conventional Commits, no AI attribution). Fallback: follow the same rules inline.
7. **Update the state file** (shared rules above).

## Subagent mode — per-task loop

Per-task subagent isolation: the implementer sees only its task, you stay clean for coordination. Artifacts (briefs, reports) go under `docs/features/.sdd/<feat-name>/` — gitignored, same folder as everything else, deleted once the plan lands in git.

For each unchecked task, in order:

1. **Write the brief** to `docs/features/.sdd/<feat-name>/task-N-brief.md` — the task's full text from the plan plus exact values (signatures, test cases, magic strings) the implementer must use verbatim. The brief is the single source of requirements; the dispatch prompt points to it, not the whole plan.
2. **Dispatch the implementer** with: (a) one line on where this task fits; (b) the brief path ("read this first — your requirements"); (c) interfaces/decisions from earlier tasks the brief can't know; (d) a report-file path `docs/features/.sdd/<feat-name>/task-N-report.md` and the report contract (full report written there; returns only status, commits, one-line test summary, concerns). Specify the model explicitly — cheap for mechanical/well-specified tasks, standard for multi-file integration. In the dispatch prompt: "Follow clean code as you write — small single-purpose functions, descriptive names, no magic numbers; manage errors where the plan expects failure." Implementers follow `dev-flow:tdd` for their test cycle (watch the test fail first; honest assertions at public seams). **Never dispatch more than one implementer in parallel** (conflicts).
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
- **A review finding asks for a behavior-preserving refactor** (rename, extract — no behavior change): apply it without writing a new failing test. The existing green suite is the guard — `dev-flow:tdd`'s Iron Law exception covers this case.

## After all tasks

- Run the **full test + lint suite** one more time. Update **Last verification** — this is the green signal the next step (review → PR) relies on.
- In subagent mode: delete `docs/features/.sdd/<feat-name>/` — the git history is the record now.
- Do **not** open the PR here — that's dev-flow step 9. Do **not** run any branch-finishing skill — this workflow's merge is manual (step 10), not a local merge.
- Hand back to `/new-feature`: it invokes `dev-flow:test` (step 6) next, then `dev-flow:review` (step 7), then advances to step 8.

## What not to do

- **No `git add -A` / `git add .`** — stage the task's files explicitly.
- **No staging or committing `docs/features/`** — state, spec, plan, and subagent briefs/reports are gitignored; if untracked shows, gitignore drifted — fix the ignore, don't commit.
- **No skipping verify-RED** — if you didn't watch the test fail (inline) or the implementer's report doesn't show it failing first (subagent), you don't know it tests the right thing.
- **No committing a red task** — tests must be green before the commit.
- **No pushing** — this skill commits only. Push is step 9.
- **No parallel implementers** (subagent mode) — one task at a time; they'd conflict.