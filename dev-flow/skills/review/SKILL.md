---
name: review
description: Use to review a feat or fix branch before opening a PR — a judgment review gate checking spec coverage, plan coverage, obvious issues (bugs, security smells, leftover, naming), and maintainability with a clean-code pass (structure, coupling, naming, complexity, duplication, functions, conditionals, comments, code smells) against the spec and plan. This is dev-flow step 7 (after the step 6 test gate, before doc-fix). Spawns a fresh independent reviewer subagent (no author bias) that runs the review and returns a verdict. Also runs standalone on any branch ("review this", "review the branch", "review my work"). Doesn't run the test suite (that's dev-flow:test), doesn't replace human PR review, and is not a line-by-line correctness scan (use a code-review tool for that) — it judges the branch against its spec and plan.
---

# Review

A pre-PR judgment review gate: does the branch do what the spec said, is anything obviously wrong, is it maintainable? It does **not** run the test suite — that's `dev-flow:test` (step 6) — and does **not** replace human review at the PR. Runs against the diff between the branch and its base.

**Fresh eyes, not self-review.** The session that wrote the code never reviews it — author bias hides the obvious issues. This skill dispatches a **fresh reviewer subagent** with no prior context: it gets the diff, spec, and plan, and returns a verdict. The orchestrator acts on it (advance to the PR, or return to execute). Same isolation principle `execute-tasks` uses for subagent-mode implementation, applied to review.

## Gate (dev-flow, step 7)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `test`. Don't advance the status here — step 7 in the orchestrator sets `review`. Wrong status → stop, tell the user which step to run. No state file (standalone) → see *Standalone mode*.

## What you need

- The **spec** at `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md` — source of truth.
- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — task breakdown.
- The **base branch** (usually `dev`). If unclear, ask — reviewing against the wrong base makes the diff meaningless.

## The verifier model (mode-split)

- **Dev-flow mode:** the orchestrator asked the **Verifier model** at step 6 and wrote it to the state file — **read it; never ask**. If missing (crash before the write), ask once, write it, proceed.
- **Standalone mode:** no state file → ask (default: same as the current session).

## Dispatch the reviewer subagent

Spawn **one** fresh reviewer subagent (Agent tool) with the chosen model. It has no prior context — hand it everything as a brief:

1. **Framing** — "You are a pre-PR reviewer. You have never seen this code before. Review the diff against the spec and plan and return a verdict; do not fix anything."
2. **Base branch + diff command** — `git diff <base>...HEAD` (plus `git log <base>..HEAD --oneline` for commit shape). Read the actual diff, not just commit messages.
3. **Spec and plan paths** — under `docs/features/`; the subagent reads them itself.
4. **The checklists** (steps 1–4) — give the subagent the **absolute path** to this skill's `references/clean-code.md` (resolved from the skill's base directory — not repo-relative: in a target repo the file lives in the plugin directory), with the instruction to read it before running the review; the subagent reads it itself. The **verdict contract** (step 5) stays pasted into the dispatch.
5. **Report contract** — full findings go to `docs/features/.review/<feat-name>/review-report.md` (gitignored); the return holds only the verdict (`green`/`blue`/`yellow`/`red`), a one-line summary, and counts (e.g. "2 yellow findings"). Detail stays in the file, keeping the orchestrator's context clean.

**Re-review: archive, never overwrite.** If `review-report.md` exists from a prior round, rename it to `review-report-<n>.md` (`-1`, `-2`, …) before dispatching. `review-report.md` is always the latest; each round keeps its record.

The reviewer runs steps 1–4 and the verdict contract (step 5), then returns the verdict. The orchestrator does **not** re-do the review — it trusts the verdict and acts on it.

## The review (run by the reviewer subagent)

Run these in order. Write findings to the report file as you go, in the color-coded format below. Do not fix anything — review and report; the orchestrator and user decide fixes.

### Report format (color-coded)

Emoji — renders in terminal + GitHub markdown, where ANSI doesn't.

**Verdict header** (one line at the top of the report):

- 🟢 **GREEN** — clean, ready for PR
- 🟦 **BLUE** — trivial findings, not worth a loop; noted for the PR, no prompt
- 🟡 **YELLOW** — findings that should be fixed; pause and ask (fix recommended)
- 🔴 **RED** — blocker, do not open PR

**Section titles** (distinct color per section):

- 🟦 **1. Spec coverage** — requirement → task → code; gaps listed
- 🟪 **2. Plan coverage** — task → matching change; lies flagged
- 🟧 **3. Obvious-issue scan** — bugs / security / leftover / naming
- 🟫 **4. Maintainability & clean code** — structure, coupling, naming, complexity, duplication, clean-code pass
- 🟥 **Findings** (only when blue/yellow/red) — numbered: severity, file:line, one-line problem, question-vs-verdict tag

Example (blue):

```markdown
# Review report — <feat-name>
🟦 BLUE — 2 trivial findings, not worth a loop; noted for the PR

🟦 1. Spec coverage
   - All spec requirements map to tasks + code. No gaps.

🟪 2. Plan coverage
   - All [x] tasks have matching changes.

🟧 3. Obvious-issue scan
   - No bugs, no leftover, naming consistent.

🟥 Findings
   1. [minor] review/SKILL.md:42 — wording says "self-review" in one spot; should say "fresh subagent".
   2. [minor] README.md:48 — stale description; doesn't mention subagent dispatch.

   (Blue advances to doc-fix with no prompt — findings noted for the PR body.)
```

### 1. Spec coverage

For each spec requirement, is there a plan task and branch code implementing it? Gaps:

- Spec requirement with no task → under-planned; surface it.
- Task with no matching code → missing work; red.
- Code matching no spec requirement → scope creep; ask keep or cut.

### 2. Plan coverage

For each `[x]` task, the code it named should exist and do what the task said — check the diff against the plan's `**Files:**` blocks. A done-marked task with no matching change is a lie the state file told itself; flag it.

### 3. Obvious-issue scan

Read the diff with fresh eyes for:

- **Bugs** — wrong logic, off-by-one, unhandled edge case the spec named, swallowed error.
- **Security** — obvious smells only: unvalidated input reaching a query/command, committed secrets, new endpoint without auth, injection-shaped code. Not a deep audit.
- **Leftover** — debug code, commented-out blocks, a file that shouldn't be committed (`docs/features/`, scratch).
- **Naming/consistency** — a symbol named one thing in the plan/tests and another in the code.

Not a deep architectural review — "is anything obviously wrong before a human looks." Unsure whether something is real? Flag it as a question, not a verdict.

### 4. Maintainability & clean code

Read the changed code in place (open the files, not just the diff hunks) — full checklist in `references/clean-code.md`.

### 5. Verdict

Return one of (verdict inline, detail in the report file):

- **Green** — step 6's test gate already green; spec covered, no obvious issues. Ready for step 8.
- **Blue** — trivial findings, not worth a loop. List them in the report; no prompt. Note the findings for the PR body; advance to step 8.
- **Yellow** — findings that should be fixed. Surface **all** of them and ask the user: fix now (recommended) vs. note-in-PR.
  - **Fix now** → orchestrator re-sets the status to `execute` (red-loop rewind); return to step 5 with the findings; fix, then re-run test (step 6) and review (step 7) with fresh subagents.
  - **Note in PR** → note the findings for the PR body; advance to step 8.
- **Red** — a blocker (spec gap, missing task, real bug). Do **not** open the PR. Return to step 5 with the findings; fix and re-run review.

## Act on the verdict (orchestrator)

The orchestrator acts on the verdict per step 5's contract above — it does not re-run the review and does not restate the handling inline. Green/blue → advance to step 8; yellow → the fix-now / note-in-PR choice per step 5; red → red-loop rewind to step 5. Step 5 owns the detail; the one-line mapping suffices.

Keep the report at `docs/features/.review/<feat-name>/review-report.md` — the run's review record (gitignored, like the spec and plan). Never delete or overwrite; the next round archives it per the re-review rule.

## Standalone mode (outside dev-flow)

No state file: ask for the base branch (or infer from `git merge-base`), read the spec/plan if the user points to them, dispatch the same fresh reviewer subagent (still ask for the model). Skip the gate. Report the verdict; the user decides next steps.

Report home without a feat-name: the **branch name** — `docs/features/.review/<branch-name>/review-report.md` (slashes flattened to dashes: `feat/9-fix-crash` → `.review/feat-9-fix-crash/`). Archive existing reports per the re-review rule.

## What not to do

- **Don't review your own work inline** — always dispatch a fresh reviewer; author bias is the point.
- **Don't re-do the review after the verdict** — trust it and act.
- **Don't let the reviewer fix things** — a reviewer that starts editing has stopped reviewing.
- **Don't open the PR** — that's step 9.
- **Don't merge** — step 10 is manual, by the human.
- **Don't run the test suite** — that's `dev-flow:test`'s job (step 6); review trusts step 6's green.
- **Don't review against the wrong base** — confirm the base first.
- **Don't pre-judge** — flag a question as a question, not a verdict.
- **Don't replace human review** — this is the gate before the PR, not the PR review itself.