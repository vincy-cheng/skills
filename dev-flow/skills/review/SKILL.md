---
name: review
description: Use to review a feature or fix branch before opening a PR — a code-review gate checking spec coverage, test green, and obvious issues against the spec and plan. This is the review step between dev-flow step 5 (execute) and step 6 (open PR). Spawns a fresh independent reviewer subagent (fresh eyes, no author bias) that does the review and returns a verdict. Also runs standalone on any branch ("review this", "review the branch", "review my work") when the user wants a pre-PR review. Does not replace human PR review; it's the gate that makes the PR reviewable.
---

# Review

A pre-PR review gate: does the branch actually do what the spec said, are all tests green, and is anything obviously wrong? It does **not** replace human review at the PR — it's what makes the PR worth reviewing. Runs against the diff between the branch and its base.

**Fresh eyes, not self-review.** The session that wrote the code does not review the code — author bias hides the obvious issues. This skill dispatches a **fresh independent reviewer subagent** that has never seen the implementation: it gets only the diff, the spec, and the plan, and returns a verdict. The orchestrating session receives the verdict and acts on it (advance to the PR, or return to execute). This is the same isolation principle `execute-tasks` uses for subagent-mode implementation, applied to review.

## Gate (dev-flow, between step 5 and 6)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `execute` before reviewing. Don't advance the status here — step 6 sets `pr-review`. If the status isn't `execute`, stop — a step was skipped — and tell the user which step to run. No state file (standalone) → see *Standalone mode* below.

## What you need

- The **spec** at `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md` — the source of truth for what was supposed to be built.
- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — the task breakdown.
- The **base branch** (the branch this work forked from — usually `dev`, or the default branch). If unclear, ask; don't guess. Confirm before reviewing — reviewing against the wrong base produces a meaningless diff.
- The repo's test + lint commands.

## Choose the reviewer model (ask the user)

Before dispatching, ask the user which model the reviewer subagent should run on. **Recommend the same model the orchestrator is running on** (the session that drove execution), so the reviewer matches the implementer's capability — then offer an override in one line. Don't punt the choice unguided, but don't belabor it either. Honor the user's pick.

Example: "Reviewer on the same model as this session (<current>)? Or a different one?" Then dispatch with the chosen model.

## Dispatch the reviewer subagent

Spawn **one** fresh reviewer subagent (Agent tool) with the chosen model. It has no prior context — hand it everything it needs as a brief; don't assume it knows the run. Give it:

1. **One line of framing** — "You are a pre-PR reviewer. You have never seen this code before. Review the diff against the spec and plan and return a verdict; do not fix anything."
2. **The base branch and how to see the diff** — `git diff <base>...HEAD` (and `git log <base>..HEAD --oneline` for the commit shape). Tell it to read the actual diff, not just the commit messages.
3. **The spec path** and **the plan path** — point to the files under `docs/features/`; the subagent reads them itself.
4. **The repo's test + lint commands** — it runs the suite itself (hard gate, see below).
5. **The review checklist** (steps 1–4 below) and the **verdict contract** (step 5) — paste them into the dispatch so the reviewer knows exactly what to check and what to return.
6. **The report contract** — the reviewer writes its full findings to `docs/features/.review/<feat-name>/review-report.md` (gitignored, same folder as everything else) and **returns only**: the verdict (`green` / `yellow` / `red`), a one-line summary, and the counts (e.g. "2 yellow findings"). The orchestrator reads the report file if it needs the detail. Keeps the orchestrator's context clean — verdict and summary inline, detail in the file.

The reviewer subagent runs steps 1–5 below and returns the verdict. The orchestrator does **not** re-do the review — it trusts the verdict and acts on it.

## The review (run by the reviewer subagent)

Run these in order. Write findings to the report file as you go, using the color-coded format below. Do not fix anything — you review and report; the orchestrator and user decide what to fix.

### Report format (color-coded)

Color via emoji — renders in terminal + GitHub markdown, where ANSI doesn't.

**Verdict header** (one line at the top of the report):

- 🟢 **GREEN** — ready for PR
- 🟡 **YELLOW** — minor findings, non-blocking
- 🔴 **RED** — blocker, do not open PR

**Section titles** (distinct color per section):

- 🟩 **1. Test + lint gate** — pass/fail per command
- 🟦 **2. Spec coverage** — requirement → task → code; gaps listed
- 🟪 **3. Plan coverage** — task → matching change; lies flagged
- 🟧 **4. Obvious-issue scan** — bugs / test honesty / leftover / naming
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

Run the full suite + lint. If anything is red or warns, **stop** — this is a hard gate, not a finding. Report it and return a `red` verdict. The PR cannot open on a red suite. If the repo has no test/lint command, say so honestly and proceed to the static checks.

```bash
<test cmd>   # e.g. flutter test, pytest, npm test, cargo test
<lint cmd>   # e.g. flutter analyze, ruff, eslint, clippy
```

Record the result in the report.

### 2. Spec coverage

For each requirement/section in the spec, can you point to a task in the plan and code on the branch that implements it? List any gap:

- A spec requirement with no task → under-planned; surface it.
- A task with no matching code → work missing; flag red.
- Code on the branch that implements no spec requirement → scope creep; surface it (ask whether to keep or cut).

### 3. Plan coverage

For each `[x]` task in the plan, the code it named should exist and do what the task said. Skim the diff against the plan's `**Files:**` blocks. A task marked done but with no matching change is a lie the state file told itself — flag it.

### 4. Obvious-issue scan

Read the diff (`git diff <base>...HEAD`) with fresh eyes for:

- **Bugs** — wrong logic, off-by-one, unhandled edge case the spec named, swallowed error.
- **Test honesty** — a test that asserts nothing, mocks the thing under test, or passes regardless of the code.
- **Leftover** — debug code, commented-out blocks, a file that shouldn't be committed (`docs/features/`, scratch).
- **Naming/consistency** — a symbol named one thing in the plan/tests and another in the code.

This is not a deep architectural review — it's "is anything obviously wrong before a human looks." When unsure whether something is a real issue, flag it as a question rather than a verdict.

### 5. Verdict

Return one of (in the dispatch return, with detail in the report file):

- **Green** — suite green, spec covered, no obvious issues. The branch is ready for step 6 (open PR).
- **Yellow** — findings that should be fixed but aren't blockers (minor). List them; recommend fixing before the PR; let the user decide whether to fix now or note in the PR body. Still hand back to step 6.
- **Red** — a blocker (suite red, spec gap, missing task, real bug). Do **not** open the PR. Return to step 5 with the specific findings; the user fixes and re-runs review.

## Act on the verdict (orchestrator)

The orchestrating session receives the verdict and acts — it does **not** second-guess the review by re-running it:

- **Green** → update the state file's **Last verification** from the reviewer's test result, then hand back to `/new-feature` to advance to step 6.
- **Yellow** → surface the findings list (from the report file) to the user; let them decide fix-now vs. note-in-PR. Update **Last verification**. Still hand back to step 6.
- **Red** → surface the blockers. Do **not** advance. Return to step 5 with the specific findings; the user fixes and re-runs review (a fresh reviewer subagent again).

Keep the report at `docs/features/.review/<feat-name>/review-report.md` — it's the run's review record (gitignored, local only, like the spec and plan). Don't delete it; a later run or the user may want to look back at what the fresh reviewer found.

## Standalone mode (outside dev-flow)

When invoked without a state file: ask for the base branch (or infer from `git merge-base`), read the spec/plan if the user points to them, and dispatch the same fresh reviewer subagent (still ask for the model). Skip the gate. The orchestrator reports the verdict; the user decides what to do next.

## What not to do

- **Don't review your own work inline** — always dispatch a fresh reviewer subagent. The session that drove execution has author bias; that's the whole point of spawning a reviewer.
- **Don't re-do the review after the verdict** — the orchestrator trusts the verdict and acts on it. Re-running it inline defeats the fresh-eyes point.
- **Don't let the reviewer fix things** — it reviews and reports; the orchestrator and user decide fixes. A reviewer that starts editing has stopped reviewing.
- **Don't open the PR** — that's step 6. Hand back with a verdict.
- **Don't merge** — step 7 is manual, by the human.
- **Don't skip the test gate** — a red suite is a hard stop, not a finding.
- **Don't review against the wrong base** — confirm the base first.
- **Don't pre-judge** — flag a question as a question, not a verdict. "Is X intentional?" helps the user; "X is wrong" when it might not be wastes a fix cycle.
- **Don't replace human review** — this is the gate before the PR, not the PR review itself.