---
name: review
description: Use to review a feature or fix branch before opening a PR — a code-review gate checking spec coverage, test green, and obvious issues against the spec and plan. This is the review step between dev-flow step 5 (execute) and step 6 (open PR). Also runs standalone on any branch ("review this", "review the branch", "review my work") when the user wants a pre-PR self-review. Does not replace human PR review; it's the gate that makes the PR reviewable.
---

# Review

A pre-PR self-review gate: does the branch actually do what the spec said, are all tests green, and is anything obviously wrong? It does **not** replace human review at the PR — it's what makes the PR worth reviewing. Runs against the diff between the branch and its base.

## Gate (dev-flow, between step 5 and 6)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `execute` before reviewing. Don't advance the status here — step 6 sets `pr-review`. If the status isn't `execute`, stop — a step was skipped — and tell the user which step to run. No state file (standalone) → proceed without the gate; ask for the base branch if unclear.

## What you need

- The **spec** at `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md` — the source of truth for what was supposed to be built.
- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — the task breakdown.
- The **base branch** (the branch this work forked from — usually `dev`, or the default branch). If unclear, ask; don't guess. Confirm before reviewing — reviewing against the wrong base produces a meaningless diff.
- The repo's test + lint commands.

## The review

Run these in order. Report findings as you go; stop and fix (or surface) before opening the PR.

### 1. Test + lint gate (hard)

Run the full suite + lint. If anything is red or warns, **stop** — this is a hard gate, not a finding. Report it and return to step 5 to fix. The PR cannot open on a red suite.

```bash
<test cmd>   # e.g. flutter test, pytest, npm test, cargo test
<lint cmd>   # e.g. flutter analyze, ruff, eslint, clippy
```

Update the state file's **Last verification** with the result.

### 2. Spec coverage

For each requirement/section in the spec, can you point to a task in the plan and code on the branch that implements it? List any gap:
- A spec requirement with no task → under-planned; surface it.
- A task with no matching code → work missing; return to step 5.
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

Report one of:
- **Green** — suite green, spec covered, no obvious issues. The branch is ready for step 6 (open PR). Hand back to `/new-feature`.
- **Yellow** — findings that should be fixed but aren't blockers (minor). List them; recommend fixing before the PR; let the user decide whether to fix now or note in the PR body. Still hand back to step 6.
- **Red** — a blocker (suite red, spec gap, missing task, real bug). Do **not** open the PR. Return to step 5 with the specific findings; the user fixes and re-runs review.

## Standalone mode (outside dev-flow)

When invoked without a state file: ask for the base branch (or infer from `git merge-base`), read the spec/plan if the user points to them, and run the same five checks. Skip the gate. Report the verdict; the user decides what to do next.

## What not to do

- **Don't open the PR** — that's step 6. Hand back with a verdict.
- **Don't merge** — step 7 is manual, by the human.
- **Don't skip the test gate** — a red suite is a hard stop, not a finding.
- **Don't review against the wrong base** — confirm the base first.
- **Don't pre-judge** — flag a question as a question, not a verdict. "Is X intentional?" helps the user; "X is wrong" when it might not be wastes a fix cycle.
- **Don't replace human review** — this is the gate before the PR, not the PR review itself.