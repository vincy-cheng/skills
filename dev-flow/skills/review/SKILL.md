---
name: review
description: Use to review a feature or fix branch before opening a PR — a code-review gate checking test green, spec coverage, obvious issues (bugs, security smells, test honesty), and maintainability (structure, coupling, naming, complexity, duplication) against the spec and plan. This is dev-flow step 5.5 (between execute and open PR). Spawns a fresh independent reviewer subagent (no author bias) that runs the review and returns a verdict. Also runs standalone on any branch ("review this", "review the branch", "review my work"). Doesn't replace human PR review — it's the gate that makes the PR reviewable.
---

# Review

A pre-PR review gate: does the branch do what the spec said, are tests green, is anything obviously wrong? It does **not** replace human review at the PR — it's what makes the PR worth reviewing. Runs against the diff between the branch and its base.

**Fresh eyes, not self-review.** The session that wrote the code never reviews it — author bias hides the obvious issues. This skill dispatches a **fresh reviewer subagent** with no prior context: it gets the diff, spec, and plan, and returns a verdict. The orchestrator acts on it (advance to the PR, or return to execute). Same isolation principle `execute-tasks` uses for subagent-mode implementation, applied to review.

## Gate (dev-flow, between step 5 and 6)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `execute`. Don't advance the status here — step 6 sets `pr-review`. Wrong status → stop, tell the user which step to run. No state file (standalone) → see *Standalone mode*.

## What you need

- The **spec** at `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md` — source of truth.
- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — task breakdown.
- The **base branch** (usually `dev`). If unclear, ask — reviewing against the wrong base makes the diff meaningless.
- The repo's test + lint commands.

## Choose the reviewer model (ask the user)

Ask which model the reviewer runs on. **Recommend the same model as the orchestrator** — the reviewer should match the implementer's capability — with a one-line override. Example: "Reviewer on the same model as this session (<current>)? Or a different one?" Honor the pick.

## Dispatch the reviewer subagent

Spawn **one** fresh reviewer subagent (Agent tool) with the chosen model. It has no prior context — hand it everything as a brief:

1. **Framing** — "You are a pre-PR reviewer. You have never seen this code before. Review the diff against the spec and plan and return a verdict; do not fix anything."
2. **Base branch + diff command** — `git diff <base>...HEAD` (plus `git log <base>..HEAD --oneline` for commit shape). Read the actual diff, not just commit messages.
3. **Spec and plan paths** — under `docs/features/`; the subagent reads them itself.
4. **Test + lint commands** — it runs the suite itself (hard gate, step 1).
5. **The checklist** (steps 1–5 below) and **verdict contract** (step 6) — paste into the dispatch.
6. **Report contract** — full findings go to `docs/features/.review/<feat-name>/review-report.md` (gitignored); the return holds only the verdict (`green`/`yellow`/`red`), a one-line summary, and counts (e.g. "2 yellow findings"). Detail stays in the file, keeping the orchestrator's context clean.

**Re-review: archive, never overwrite.** If `review-report.md` exists from a prior round, rename it to `review-report-<n>.md` (`-1`, `-2`, …) before dispatching. `review-report.md` is always the latest; each round keeps its record.

The reviewer runs steps 1–6 and returns the verdict. The orchestrator does **not** re-do the review — it trusts the verdict and acts on it.

## The review (run by the reviewer subagent)

Run these in order. Write findings to the report file as you go, in the color-coded format below. Do not fix anything — review and report; the orchestrator and user decide fixes.

### Report format (color-coded)

Emoji — renders in terminal + GitHub markdown, where ANSI doesn't.

**Verdict header** (one line at the top of the report):

- 🟢 **GREEN** — ready for PR
- 🟡 **YELLOW** — minor findings, non-blocking
- 🔴 **RED** — blocker, do not open PR

**Section titles** (distinct color per section):

- 🟩 **1. Test + lint gate** — pass/fail per command
- 🟦 **2. Spec coverage** — requirement → task → code; gaps listed
- 🟪 **3. Plan coverage** — task → matching change; lies flagged
- 🟧 **4. Obvious-issue scan** — bugs / security / test honesty / leftover / naming
- 🟫 **5. Maintainability** — structure, coupling, naming, complexity, duplication
- 🟥 **Findings** (only when yellow/red) — numbered: severity, file:line, one-line problem, question-vs-verdict tag

Example (yellow):

```markdown
# Review report — <feat-name>
🟡 YELLOW — 2 minor findings, non-blocking

🟩 1. Test + lint gate
   - npm test — passed (42 tests)
   - eslint — clean

🟦 2. Spec coverage
   - All spec requirements map to tasks + code. No gaps.

🟪 3. Plan coverage
   - All [x] tasks have matching changes.

🟧 4. Obvious-issue scan
   - No bugs, test honesty OK, no leftover.

🟥 Findings
   1. [minor] review/SKILL.md:42 — wording says "self-review" in one spot; should say "fresh subagent".
   2. [minor] README.md:48 — stale description; doesn't mention subagent dispatch.
```

### 1. Test + lint gate (hard)

Run the full suite + lint. Anything red or warning → **stop**, report, return `red`. A PR cannot open on a red suite. No test/lint command in the repo → say so and proceed to the static checks.

```bash
<test cmd>   # e.g. flutter test, pytest, npm test, cargo test
<lint cmd>   # e.g. flutter analyze, ruff, eslint, clippy
```

### 2. Spec coverage

For each spec requirement, is there a plan task and branch code implementing it? Gaps:

- Spec requirement with no task → under-planned; surface it.
- Task with no matching code → missing work; red.
- Code matching no spec requirement → scope creep; ask keep or cut.

### 3. Plan coverage

For each `[x]` task, the code it named should exist and do what the task said — check the diff against the plan's `**Files:**` blocks. A done-marked task with no matching change is a lie the state file told itself; flag it.

### 4. Obvious-issue scan

Read the diff with fresh eyes for:

- **Bugs** — wrong logic, off-by-one, unhandled edge case the spec named, swallowed error.
- **Security** — obvious smells only: unvalidated input reaching a query/command, committed secrets, new endpoint without auth, injection-shaped code. Not a deep audit.
- **Test honesty** — a test that asserts nothing, mocks the thing under test, or passes regardless of the code.
- **Leftover** — debug code, commented-out blocks, a file that shouldn't be committed (`docs/features/`, scratch).
- **Naming/consistency** — a symbol named one thing in the plan/tests and another in the code.

Not a deep architectural review — "is anything obviously wrong before a human looks." Unsure whether something is real? Flag it as a question, not a verdict.

### 5. Maintainability

Read the changed code in place (open the files, not just the diff hunks) — what does the next maintainer inherit?

- **Structure** — one thing per module/function; new code follows existing patterns?
- **Coupling** — layering violations, hidden dependencies, leaked internals.
- **Naming** — names that say what things do, not just locally true ones.
- **Complexity** — deep nesting, long functions, branching a simpler shape would kill.
- **Duplication** — logic copied from elsewhere in the codebase (diff-only reading misses this).

Report findings with file:line and a concrete suggested shape ("extract X into Y") — suggest, don't fix. Can be yellow or red; severity is the reviewer's judgment.

### 6. Verdict

Return one of (verdict inline, detail in the report file):

- **Green** — suite green, spec covered, no obvious issues. Ready for step 6.
- **Yellow** — minor, non-blocking findings. List them; recommend fixing before the PR; let the user decide fix-now vs. note-in-PR. Still hand back to step 6.
- **Red** — a blocker (suite red, spec gap, missing task, real bug). Do **not** open the PR. Return to step 5 with the findings; fix and re-run review.

## Act on the verdict (orchestrator)

The orchestrator acts on the verdict — it does not re-run the review:

- **Green** → update the state file's **Last verification** from the reviewer's test result, hand back to `/new-feature` for step 6.
- **Yellow** → surface the findings; let the user decide fix-now vs. note-in-PR. Update **Last verification**. Still hand back to step 6.
- **Red** → surface the blockers. Do not advance. Return to step 5 with the findings; the user fixes and re-runs review (fresh reviewer again).

Keep the report at `docs/features/.review/<feat-name>/review-report.md` — the run's review record (gitignored, like the spec and plan). Never delete or overwrite; the next round archives it per the re-review rule.

## Standalone mode (outside dev-flow)

No state file: ask for the base branch (or infer from `git merge-base`), read the spec/plan if the user points to them, dispatch the same fresh reviewer subagent (still ask for the model). Skip the gate. Report the verdict; the user decides next steps.

Report home without a feat-name: the **branch name** — `docs/features/.review/<branch-name>/review-report.md` (slashes flattened to dashes: `feature/9-fix-crash` → `.review/feature-9-fix-crash/`). Archive existing reports per the re-review rule.

## What not to do

- **Don't review your own work inline** — always dispatch a fresh reviewer; author bias is the point.
- **Don't re-do the review after the verdict** — trust it and act.
- **Don't let the reviewer fix things** — a reviewer that starts editing has stopped reviewing.
- **Don't open the PR** — that's step 6.
- **Don't merge** — step 7 is manual, by the human.
- **Don't skip the test gate** — a red suite is a hard stop, not a finding.
- **Don't review against the wrong base** — confirm the base first.
- **Don't pre-judge** — flag a question as a question, not a verdict.
- **Don't replace human review** — this is the gate before the PR, not the PR review itself.