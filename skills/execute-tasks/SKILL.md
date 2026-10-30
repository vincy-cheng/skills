---
name: execute-tasks
description: "Use to execute a dev-flow plan task by task. This is step 5 of the dev-flow workflow — work the plan's tasks with TDD (failing test → implement → green → commit per task), updating the state file as you go. The Implementer dispatches per the state file's Roles block lane: inline (runs in this session), session, claude:<name>, or cli:<tool>/<model> (external CLI via thin-driver). Can be invoked standalone if a plan and state file already exist."
---

# Execute tasks

Run the plan's tasks one by one, with TDD. Commit per task. Keep the state file honest. All artifacts stay under `docs/features/`; no `.superpowers/` workspace.

## Gate (dev-flow step 5)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `issue` — or is already `execute` for the documented resume/red-loop re-entry — before starting. On `issue`, set `execute` before work, with the `Status since:` timestamp (third write of the status-transition protocol). If neither `issue` nor valid `execute` re-entry applies, stop — a step was skipped — and tell the user which step to run.

Then **verify the branch before any work**: the current branch (`git branch --show-current`) must equal the state file's **Base branch** (the `feat/<n>-<name>` / `fix/<n>-<name>` branch step 4 created). Mismatch → stop and ask — don't switch or commit anything yourself; the user may have uncommitted work where they are. Executing on the wrong branch commits another branch's history into the run — this check is cheap and prevents the most damaging silent mistake in the flow. No state file (standalone) → require a plan path from the user; proceed without the gate.

## Before starting

Dev-flow mode — read the state file's **Roles block** (the Implementer line) before any task work:

- Block has an Implementer lane value (`inline`, `session`, `claude:<name>`, `cli:<tool>/<model>`) → dispatch per `## Model routing`.
- Block missing, empty, or the Implementer line absent → **stop; report "step 5's combined Roles ask was skipped"** — do not do any task work, do not re-ask from this skill. Return to new-feature step 5 (the orchestrator asks and writes the picks, then re-invokes). A stop here is a visible gate failure, the same form as the Goal-status gate.
- Malformed lane value (unknown syntax) → BLOCKED stop-and-ask per `references/model-routing.md`'s error contract — never treated as unset.
- Pre-Roles state file (no `## Roles` block): apply the upgrade mapping in new-feature's field rules (old `Implementer mode: inline` → `inline`; old `subagent` no-model → `session`; old `subagent` + model → `claude:<name>`) — read-only, never migrated on disk.
- Read the optional **Codex implementer model** field as the confirmed run choice: do not re-ask it or unrelated roles. On legacy state with the field missing, keep the stored mode; if configuration has no implementer key, preserve the existing default; if it has a configured model, ask for explicit confirmation before changing mode or claiming that saved model.
- Missing or malformed required implementation state blocks before task work.

Standalone mode (no state file) → there is no step 5 to return to; this skill asks the Implementer lane itself in `## Choose a mode` below.

## What you need before starting

- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — read it once; note its Global Constraints and task list.
- The **state file** — its **Tasks** section mirrors the plan. If it already has `[x]` tasks, resume at the first unchecked one (don't redo done work).
- The repo's test + lint commands (e.g. `flutter test`, `pytest`, `npm test`, `cargo test`). Run them per task and for the final suite.

## Choose a mode

**Dev-flow mode: the Implementer lane is already decided** — the orchestrator asked at step 5 (combined Roles ask) and wrote it to the state file's Roles block; `## Before starting` read it. Do not ask again. This section's recommendation logic ran at step 5 (the orchestrator read the same signal); resume reads the stored pick and proceeds without re-asking.

**Standalone mode (no state file): ask here.** Read the plan's signal first, then ask the dev-flow equivalent for execution mode and implementation model together and **recommend** an Implementer lane (`inline`, or a subagent lane — `session` by default) with one line of reasoning, offering an override. On Codex, include native-subagent mode and the optional `.dev-flow/config.json` `codex_implementer_model`; retain the confirmed choice throughout the execution loop. On Claude Code, keep the existing lane ask and ignore that Codex-only key. Don't punt the choice unguided — and don't skip the ask (a small or markdown-only plan is not an exemption). Lead with the recommendation, not a bare "which mode?".

Signal to read: **task count**, **file spread** (how many files the tasks touch), **task coupling** (do later tasks depend on earlier tasks' exact symbols/wording?).

- **`inline`** when ≤3 tasks, docs-only/markdown edits (no test cycle to isolate), or tightly-coupled tasks (subagent isolation *hurts* here); simplest, and you stay in the loop.
- **A subagent lane** (`session`, `claude:<name>`, `cli:<tool>/<model>`) when ≥5 tasks, many files, or genuinely independent tasks (per-task context isolation is a feature). For each task, dispatch a fresh implementer with only that task's brief, then review its work yourself before committing. Independence routes a task to subagent dispatch for **context isolation only** — it is never license for parallel dispatch (one implementer at a time, always).
- **Ambiguous middle** → recommend **`inline`** (staying in the loop wins when the signal is mixed) but name the tradeoff: subagent dispatch buys isolation at the cost of context handoff overhead.

Example: "4 tasks, all in `new-feature.md` (one file, tightly coupled — each edit builds on the prior's wording) → inline. Override to a subagent lane?"

## Model routing

Lane semantics, the `claude:<name>` resolution rule, availability checks, and the thin-driver flow live in `references/model-routing.md` — the single source; this skill does not re-derive them.

- **`inline`** → the shared per-task loop runs in this session; no dispatch.
- On Claude Code, **`session` / `claude:<name>`** → the "Subagent dispatch" loop below, dispatching via the Agent tool with the resolution rule's model-param / agent-type shape.
- **`cli:<tool>/<model>`** (v1: `cli:codex/<model>`) → the same loop with the thin-driver flow: the brief + report contract copied verbatim from this skill's own dispatch/report sections into `docs/features/.routing/<feat>/`, the CLI run from the driver subagent, the external model writing the implementer report (containing the RED-phase test output verbatim) to the same `task-N-report.md` path. **The external model never commits** — the driver scopes the diff and commits via `dev-flow:commit`. Sandbox: `workspace-write` per the routing doc's map. Availability checks fail (binary, auth, Bash) → BLOCKED stop-and-ask, never a silent downgrade.

- On Codex, native implementation (`session`) uses the saved **Codex implementer model** through the routing doc's shared contract. It is separate from Claude lanes and from the reviewer/tester contracts; `claude:<name>` is not reinterpreted as a native Codex model. Revalidate and keep one implementer at a time. The dispatcher self-reviews and commits via `dev-flow:commit`.
- A pinned native model stays across NEEDS_CONTEXT, blocked handling, and review rework unless the user explicitly changes it. A Claude lane keeps its existing resolution; an external CLI keeps its thin-driver path.

The rest of this skill has a shared core (state-file updates, stuck handling, after-all-tasks) plus a per-task loop that differs by mode.

## Shared: state-file updates (both modes)

On every task start and complete, and every test run:
- Flip the task's checkbox (`[ ]` → `[x]` on complete); bump **Updated**.
- Refresh **Last verification** with the latest test + lint result. A green run clears any `⚠ test failing` annotation on that task.
- If a task's test is currently red, annotate its line `— ⚠ test failing: <one-line reason>`; clear when green. Leave passing/pending un-annotated.
- For inline execution, record execution mode/model provenance in the state's execution note; do not create a separate report subsystem.
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

## Subagent dispatch — per-task loop (`session` / `claude:<name>` / `cli:<tool>/<model>`)

Per-task subagent isolation: the implementer sees only its task, you stay clean for coordination. Artifacts (briefs, reports) go under `docs/features/.sdd/<feat-name>/` — gitignored, same folder as everything else, deleted once the plan lands in git.

For each unchecked task, in order:

1. **Write the brief** to `docs/features/.sdd/<feat-name>/task-N-brief.md` — the task's full text from the plan plus exact values (signatures, test cases, magic strings) the implementer must use verbatim. The brief is the single source of requirements; the dispatch prompt points to it, not the whole plan.
2. **Dispatch the implementer** with: (a) one line on where this task fits; (b) the brief path ("read this first — your requirements"); (c) interfaces/decisions from earlier tasks the brief can't know; (d) a report-file path `docs/features/.sdd/<feat-name>/task-N-report.md` and the report contract (full report written there; returns only status, commits, one-line test summary, concerns, and an **Execution model** line recording the configured native selection or explicit session default — never an actual backend identifier unless the tool exposes one). Dispatch with the selected lane's existing model rule. For native Codex implementation, use the confirmed choice through `## Model routing` and never choose a different model from task shape. In the dispatch prompt: "Follow clean code as you write — small single-purpose functions, descriptive names, no magic numbers; manage errors where the plan expects failure." Implementers follow `dev-flow:tdd` for their test cycle (watch the test fail first; honest assertions at public seams). **Never dispatch more than one implementer in parallel** — serial is a correctness rule (rationale in the "What not to do" entry below).
3. **Handle the report:**
   - **DONE** → review (step 4).
   - **DONE_WITH_CONCERNS** → read concerns; address correctness/scope ones before review, note observations and proceed.
   - **NEEDS_CONTEXT** → provide the missing context, then retry with the same confirmed native selection, revalidated per `## Model routing`; no model/mode/lane switch without explicit user direction.
   - **BLOCKED** → assess: context problem → re-dispatch with more context; a model change to something more capable requires explicit user direction (otherwise BLOCKED); task too large → split it or surface to the user; plan wrong → surface to the user.
4. **Review the task yourself** — you hold cross-task context the implementer lacks. Read the diff (`git diff <BASE>..HEAD`, where BASE is the commit before the implementer ran). Check: spec/task compliance, test honesty (asserts real behavior, watched it fail), no leftover/debug, no scope creep. This is a single self-review by you, not a subagent. If clean → step 5. If not → send the findings back to the implementer (re-dispatch with the open findings; up to 3 rounds on the same confirmed choice; a fresh/more-capable implementer requires explicit user direction; after 5, adjudicate: park or surface as BLOCKED).
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
- In subagent-dispatch lanes (`session`/`claude:`/`cli:`): delete `docs/features/.sdd/<feat-name>/` (and `.routing/<feat>/` on the cli lane) — the git history is the record now.
- Do **not** open the PR here — that's dev-flow step 9. Do **not** run any branch-finishing skill — this workflow's merge is manual (step 10), not a local merge.
- Hand back to `/new-feature`: it invokes `dev-flow:test` (step 6) next, then `dev-flow:review` (step 7), then advances to step 8.

## What not to do

- **No `git add -A` / `git add .`** — stage the task's files explicitly.
- **No staging or committing `docs/features/`** — state, spec, plan, and subagent briefs/reports are gitignored; if untracked shows, gitignore drifted — fix the ignore, don't commit.
- **No skipping verify-RED** — if you didn't watch the test fail (inline) or the implementer's report doesn't show it failing first (subagent), you don't know it tests the right thing.
- **No committing a red task** — tests must be green before the commit.
- **No pushing** — this skill commits only. Push is step 9.
- **No parallel implementers** (any subagent lane) — one at a time, and that's a correctness rule, not a convenience one. Conflicts are only the symptom of a shared tree; even with git-worktree isolation the three real reasons survive: TDD verify-RED attribution (a red test must be attributable to its task — across worktrees, that judgment breaks), per-task commit ordering (each commit gates on the prior task's green suite), and integration (serial — tasks are rarely independent enough to parallelize, and coordinator-side review+commit is serial anyway, so worktrees buy little wall-clock for much correctness risk).