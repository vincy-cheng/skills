---
name: review
description: Use to review a feat or fix branch before opening a PR — a judgment review gate checking spec coverage, plan coverage, obvious issues (bugs, security smells, leftover, naming), and maintainability with a clean-code pass (structure, coupling, naming, complexity, duplication, functions, conditionals, comments, code smells) against the spec and plan. This is dev-flow step 7 (after the step 6 test gate, before doc-fix). Spawns a fresh independent reviewer subagent (no author bias) that runs the review and returns a verdict; on a high risk tier (state file's Risk tier is `high` and not waived) it also dispatches a second fresh focused reviewer that deep-scans the triggered risk categories after the main reviewer clears green/blue. Also runs standalone on any branch ("review this", "review the branch", "review my work") — standalone runs have no risk tier. Doesn't run the test suite (that's dev-flow:test), doesn't replace human PR review, and is not a line-by-line correctness scan (use a code-review tool for that) — it judges the branch against its spec and plan.
---

# Review

A pre-PR judgment review gate: does the branch do what the spec said, is anything obviously wrong, is it maintainable? It does **not** run the test suite — that's `dev-flow:test` (step 6) — and does **not** replace human review at the PR. Runs against the diff between the branch and its base.

**Fresh eyes, not self-review.** The session that wrote the code never reviews it — author bias hides the obvious issues. This skill dispatches a **fresh reviewer subagent** with no prior context: it gets the diff, spec, and plan, and returns a verdict. The orchestrator acts on it (advance to the PR, or return to execute) — the same dispatch isolation principle `execute-tasks` uses for implementation.

## Gate (dev-flow, step 7)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `test`. Don't advance the status here — step 7 in the orchestrator sets `review`. Wrong status → stop, tell the user which step to run. No state file (standalone) → see *Standalone mode*.

## Before starting

Dev-flow mode — verify the state file's **Roles block** (the Reviewer line) before dispatching the reviewer, then select the host:

- Block missing, empty, or the Reviewer line absent → **stop; report "step 5's combined Roles ask was skipped"** — do not dispatch the reviewer, do not re-ask from this skill. Return to new-feature step 5 (the orchestrator asks and writes the picks, then re-invokes). A stop here is a visible gate failure, the same form as the Goal-status gate.
- **Codex:** once the Reviewer line is present, ignore its Claude lane value for model selection and follow `## Model routing`. Validate the Codex config, not the lane syntax or Claude model availability.
- **Claude Code:** a Reviewer lane value (`session`, `claude:<name>`, `cli:<tool>/<model>`) dispatches per `## Model routing`. A malformed lane value → BLOCKED stop-and-ask per `references/model-routing.md`'s error contract — never treated as unset.
- Missing-block recovery paths (user-confirmed crash-recovery, pre-Roles upgrade mapping) → follow `references/model-routing.md`'s *Before-starting procedures* section — the only ask-from-here path is a user-confirmed crash recovery; every other missing-block shape stays a stop.

Then read the state file's **Risk tier**:

- Field `low`, `high — <categories>`, or `high — waived by user, <date>` → proceed per the tier: `high` (not waived) adds the focused review below; `low` and waived-high run the main reviewer only.
- Field absent or `_(not asked — step-7 recheck pending)_` → **stop; report "step 7's risk recheck was skipped"** — do not dispatch any reviewer, do not re-run the recheck from this skill. Return to new-feature step 7 (the orchestrator runs the recheck, writes the tier, then re-invokes). Fail-closed: a missing tier is a skipped recheck, never a low.
- Tier `high` (not waived) and **Focused verdict** `_(skipped)_` → stop; report "the focused review was skipped" — the field only ever gets `_(skipped)_` out-of-band (a user dropping the requirement after the fact); a fresh or reset gate round carries `_(pending — run in this gate round)_` and dispatches the focused review as usual after the main reviewer clears green/blue. Absent field on a live high tier → treat as `_(pending — run in this gate round)_` — never as "already covered", and never as `_(not required)_`.

Standalone mode (no state file) → there is no step 5 ask and no risk tier. Codex resolves the optional config directly; Claude Code asks the Reviewer lane (see *Standalone mode* below).

## What you need

- The **spec** at `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md` — source of truth.
- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — task breakdown.
- The **base branch** — usually the state file's Base branch (`dev` by default, or `.dev-flow/config.json`'s `dev_branch`); standalone mode: ask if unclear — reviewing against the wrong base makes the diff meaningless.

## Dispatch the reviewer subagent

Dev-flow mode: check the Reviewer line per `## Before starting` — never ask. Standalone: choose the host-specific route below.

**Codex:** before dispatch, resolve `codex_reviewer_model` per **Codex reviewer model** in `references/model-routing.md`, including its validation and native `model` rules. **Claude Code:** use the Reviewer lane from the state (standalone: ask, default `session`).

Spawn **one** fresh reviewer subagent using that route. It has no prior context — hand it everything as a brief:

1. **Framing** — "You are a pre-PR reviewer. You have never seen this code before. Review the diff against the spec and plan and return a verdict; do not fix anything."
2. **Base branch + diff command** — `git diff <base>...HEAD` (plus `git log <base>..HEAD --oneline` for commit shape). Read the actual diff, not just commit messages.
3. **Spec and plan paths** — under `docs/features/`; the subagent reads them itself.
4. **The methodology** (R1–R4) — give the subagent the **absolute path** to this skill's `references/clean-code.md` (resolved from the skill's base directory — not repo-relative: in a target repo the file lives in the plugin directory), with the instruction to read it first as the review's checklist; the subagent reads it itself. Paste **R1–R2's and R3's section bodies** (spec coverage / plan coverage / obvious-issue scan) into the dispatch — the reference file carries only the R4 clean-code checklist, not the full methodology — and paste the **verdict contract** (R5) too.
5. **Report contract** — full findings go to `docs/features/.review/<feat-name>/review-report.md` (gitignored); the return holds only the verdict (`green`/`blue`/`yellow`/`red`), a one-line summary, and counts (e.g. "2 yellow findings"). Detail stays in the file, keeping the orchestrator's context clean.

**Re-review: archive, never overwrite.** If `review-report.md` exists from a prior round, rename it to `review-report-<n>.md` (`-1`, `-2`, …) before dispatching. `review-report.md` is always the latest; each round keeps its record.

The reviewer runs R1–R4 and the verdict contract (R5), then returns the verdict. The orchestrator does **not** re-do the review — it trusts the verdict and acts on it.

**Claude Code lane shapes** (Codex uses the native route above):

- **`session` / `claude:<name>`** → Agent-tool dispatch, shape per `## Model routing`'s resolution rule.
- **`cli:<tool>/<model>`** (v1: `cli:codex/<model>`) → thin-driver flow per `references/model-routing.md`: the driver composes the brief + report contract (copied **verbatim at runtime** from this skill's brief/report sections above) into `docs/features/.routing/<feat>/`, runs the CLI (`--sandbox read-only` per the routing doc's sandbox map), and the external model writes its full report to the same report path. **The relayed payload must carry the verdict + full findings verbatim** — the R5 yellow choice (fix-now vs note-in-PR) must reach the user uncompressed. Availability failures → BLOCKED stop-and-ask, never a silent downgrade.

## Model routing

Host selection, availability checks, and dispatch rules live in `references/model-routing.md` — the single source. **Codex:** resolve `codex_reviewer_model` per **Codex reviewer model** there before every dispatch; record a configured model in the report. **Claude Code:** use the Reviewer lane from the state file's Roles block (dev-flow) or the standalone ask; malformed or unavailable lanes → BLOCKED stop-and-ask. Both reviewers share the same host-specific model source. Roles block missing → stop per `## Before starting`; never silently downgrade.

## The review (run by the reviewer subagent)

Run these in order. Write findings to the report file as you go, in the color-coded format below. Do not fix anything — review and report; the orchestrator and user decide fixes.

### Report format (color-coded)

Emoji — renders in terminal + GitHub markdown, where ANSI doesn't.

**Verdict header** (one line at the top of the report): 🟢 **GREEN** — clean, ready for PR; 🟦 **BLUE** — trivial findings, not worth a loop; noted for the PR, no prompt; 🟡 **YELLOW** — findings that should be fixed; pause and ask (fix recommended); 🔴 **RED** — blocker, do not open PR.

**Section titles** (distinct color per section): 🟦 **R1. Spec coverage** — requirement → task → code; gaps listed / 🟪 **R2. Plan coverage** — task → matching change; lies flagged / 🟧 **R3. Obvious-issue scan** — bugs / security / leftover / naming / 🟫 **R4. Maintainability & clean code** — structure, coupling, naming, complexity, duplication, clean-code pass / 🟥 **Findings** (only when blue/yellow/red) — numbered: severity, file:line, one-line problem, question-vs-verdict tag.

Example (blue): `# Review report — <feat-name>` / `🟦 BLUE — 2 trivial findings, not worth a loop; noted for the PR`, then one section per row above with the findings numbered under 🟥 (severity, file:line, one-line problem), ending with `(Blue asks the user — fix now vs. note-in-PR.)`.

### R1. Spec coverage

For each spec requirement, is there a plan task and branch code implementing it? Gaps:

- Spec requirement with no task → under-planned; surface it.
- Task with no matching code → missing work; red.
- Code matching no spec requirement → scope creep; ask keep or cut.

### R2. Plan coverage

For each `[x]` task, the code it named should exist and do what the task said — check the diff against the plan's `**Files:**` blocks. A done-marked task with no matching change is a lie the state file told itself; flag it.

### R3. Obvious-issue scan

Read the diff with fresh eyes for:

- **Bugs** — wrong logic, off-by-one, unhandled edge case the spec named, swallowed error.
- **Security** — obvious smells only: unvalidated input reaching a query/command, committed secrets, new endpoint without auth, injection-shaped code. Not a deep audit.
- **Leftover** — debug code, commented-out blocks, a file that shouldn't be committed (`docs/features/`, scratch).
- **Naming/consistency** — a symbol named one thing in the plan/tests and another in the code.

Not a deep architectural review — "is anything obviously wrong before a human looks." Unsure whether something is real? Flag it as a question, not a verdict.

### R4. Maintainability & clean code

Read the changed code in place (open the files, not just the diff hunks) — full checklist in `references/clean-code.md`.

### R5. Verdict

Return one of (verdict inline, detail in the report file):

- **Green** — step 6's test gate already green; spec covered, no obvious issues. Ready for step 8.
- **Blue** — trivial findings, not worth a loop. List them in the report, then **ask the user: fix now vs. note-in-PR** (fix is the default recommendation — a trivial fix is cheap and the user may want it; but the choice is theirs, not the skill's). Fix now → treat as yellow's fix-now path (red-loop rewind with the findings). Note in PR → note the findings for the PR body; advance to step 8.
- **Yellow** — findings that should be fixed. Surface **all** of them and ask the user: fix now (recommended) vs. note-in-PR.
  - **Fix now** → orchestrator re-sets the status to `execute` (red-loop rewind); return to step 5 with the findings; fix, then re-run test (step 6) and review (step 7) with fresh subagents.
  - **Note in PR** → note the findings for the PR body; advance to step 8.
- **Red** — a blocker (spec gap, missing task, real bug). Do **not** open the PR. Return to step 5 with the findings; fix and re-run review.

## Act on the verdict (orchestrator)

The orchestrator acts on the verdict per contract R5 above — it does not re-run the review and does not restate the handling inline. Keep the report at `docs/features/.review/<feat-name>/review-report.md` — the run's review record (gitignored, like the spec and plan). Never delete or overwrite; the next round archives it per the re-review rule. A focused review's report lives beside it at `review-report-focused.md`, same rules.

On a high (not waived) tier, the act-on-verdict step also covers the focused reviewer's verdict once it returns: record it in the state's **Focused verdict** field (replacing `_(pending — run in this gate round)_`), then apply the same R5 handling — both reviewers must clear.

## Focused review (high risk tier only)

Triggers when the state's **Risk tier** is `high — <categories>` (not waived), after the main reviewer's verdict clears green/blue. **Serial placement, for its real trade-off:** serial saves the tokens a parallel focused verdict would burn when a main-review yellow/red rewinds to step 5 and invalidates it; parallel saves wall-clock but its verdict gets thrown away on rewind. The focused reviewer always scans the final diff.

**Dispatch** — one fresh focused reviewer subagent. **Codex:** re-resolve `codex_reviewer_model` before dispatch per **Codex reviewer model** in `references/model-routing.md`; validate current availability and use the native route. **Claude Code:** use the state's **Reviewer lane**. Both share the main reviewer's model source — no second ask or separate setting. Use the same fresh-eyes framing: "You are a focused risk reviewer. You have never seen this code before. Deep-scan the diff for your assigned risk categories and return a verdict; do not fix anything." Give it the base branch + diff command, the spec/plan paths, the R5 verdict contract, and the **combined brief** — one brief covering all triggered categories:

- **destructive-operations** → blast radius of each destructive command, backup paths, recovery story.
- **auth-permissions** → permission boundaries deeper than R3's obvious-smell scan: auth spine, middleware, permission checks, session handling.
- **executable-code** → each newly introduced privileged/triggered execution path: what triggers it, what it can do, who can reach it.
- **blast-radius** → whether the diff's breadth is justified by the spec, or scope creep wearing a costume.

**Any number of triggered categories → still one focused reviewer** with the combined brief; when >2 categories trigger, add a one-line user note (a wide risk surface is worth their attention — it is not a plan defect and there is no bounce).

**Report + verdict** — same R5 contract and color-coded report format, written to `docs/features/.review/<feat-name>/review-report-focused.md` (gitignored; same archive rules — never shares the main report's path). The return holds only the verdict + one-line summary + counts. The orchestrator records the verdict in the state's **Focused verdict** field, then acts: **hard gate — both reviewers must clear.** Any red → red-loop rewind to step 5 (same as a main-review red); yellow → the same fix-now / note-in-PR prompt; green/blue → advance to step 8.

## Standalone mode (outside dev-flow)

No state file: ask for the base branch (or infer from `git merge-base`), read the spec/plan if the user points to them, and dispatch the same fresh reviewer subagent. **Codex:** resolve the optional config per `## Model routing`, without a Claude lane ask. **Claude Code:** ask for the Reviewer lane; default `session`. Skip the gate. Report the verdict; the user decides next steps. Risk-tier is a dev-flow gate feature (state file + plan Risk lines) — a standalone review has no tier, no focused reviewer, and the user owns their own review depth.

Report home without a feat-name: the **branch name** — `docs/features/.review/<branch-name>/review-report.md` (slashes flattened to dashes: `feat/9-fix-crash` → `.review/feat-9-fix-crash/`). Archive existing reports per the re-review rule.

## What not to do

- **Don't re-do the review after the verdict** — trust it and act.
- **Don't let the reviewer fix things** — a reviewer that starts editing has stopped reviewing.
- **Don't open the PR** — that's step 9, and step 10's merge is manual.
- **Don't run the test suite** — that's `dev-flow:test`'s job (step 6); review trusts step 6's green.
- **Don't pre-judge** — flag a question as a question, not a verdict — and don't review against the wrong base.
