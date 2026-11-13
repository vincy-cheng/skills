---
name: review
description: Use to review a feat or fix branch before opening a PR — a judgment review gate checking spec coverage, plan coverage, obvious issues (bugs, security smells, leftover, naming), and maintainability with a clean-code pass (structure, coupling, naming, complexity, duplication, functions, conditionals, comments, code smells) against the spec and plan. This is dev-flow step 7 (after the step 6 test gate, before doc-fix). Dispatches a fresh independent main reviewer group (no author bias); on a high risk tier (state file's Risk tier is `high` and not waived), it also dispatches a focused reviewer group after the main group's R5 handling clears. Also runs standalone on any branch ("review this", "review the branch", "review my work") — standalone runs have no risk tier. Doesn't run the test suite (that's dev-flow:test), doesn't replace human PR review, and is not a line-by-line correctness scan (use a code-review tool for that) — it judges the branch against its spec and plan.
---

# Review

## Output style

Before writing responses or human-readable files, load [`references/output-style.md`](../../references/output-style.md) from the plugin root (the directory containing `references/`, not the target repository root). Pass its actual contents to every subagent you dispatch, including isolated reviewers. User requirements and specific output contracts take precedence.

A pre-PR judgment review gate: does the branch do what the spec said, is anything obviously wrong, is it maintainable? It does **not** run the test suite — that's `dev-flow:test` (step 6) — and does **not** replace human review at the PR. Runs against the diff between the branch and its base.

**Read the report before deciding.** The orchestrator reads the review report and presents every decision-relevant finding. A concise transport return is not a substitute for the findings needed to act.

**Fresh eyes, not self-review.** The session that wrote the code never reviews it — author bias hides the obvious issues. This skill dispatches a **fresh reviewer subagent** with no prior context: it gets the diff, spec, and plan, and returns a verdict. The orchestrator acts on it (advance to the PR, or return to execute) — the same dispatch isolation principle `execute-tasks` uses for implementation.

## Gate (dev-flow, step 7)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `test`. Don't advance the status here — step 7 in the orchestrator sets `review`. Wrong status → stop, tell the user which step to run. The only exception is an explicit Step 10 `pr-review` validation delegation from `new-feature`; it does not change Goal status or permit ordinary review dispatch. No state file (standalone) → see *Standalone mode*.

## Post-PR validation (explicit Step 10 delegation only)

When Step 10 explicitly delegates `pr-review` validation, inspect the current PR and saved evidence before dispatch. A prior review is reusable only when its report exists, its R5 outcome is clear to proceed (including any yellow finding's recorded handling), and its repository, head SHA, base ref, and base SHA exactly match the current PR. Any focused review required by the recorded risk tier must also have a clear verdict and report for those same version values, or a recorded user waiver. If all required evidence matches, reuse the review without repeating it. For test evidence, Step 10 requires an existing report, a green verdict, and exact repository/head/base matches; missing or stale test evidence is handled by Step 10's delegated test subflow, which records its result and returns to the test gate on failure. These evidence checks never advance or rewrite Goal status.

For a changed head, incremental review is allowed only when the prior review report exists with a green or blue verdict, its R5 outcome is clear to proceed (including any yellow finding's recorded handling), any focused review required by the prior risk tier has a clear verdict and report for that same repository/head/base tuple or a recorded user waiver, the repository matches, the base ref and base SHA are unchanged, and `git merge-base --is-ancestor <reviewed-head> <current-head>` succeeds. This requires the prior complete review gate to have cleared; a green or blue main report alone is not a baseline. Review `<reviewed-head>..<current-head>` plus the previous report and any affected callers or other related changes, including doc-fix commits. Archive the old report before writing the new report and record the prior report path. A failed ancestry check, missing or invalid report/verdict, changed repository, changed base ref/SHA, or unavailable evidence requires a full review of the current PR diff; when eligibility fails, rerun the risk recheck across that full diff so earlier high-risk categories remain covered even when the new delta does not trigger them. Do not infer approval for new scope from a full review.

For either scope, rerun the existing escalation-only risk recheck against the newly reviewed changes. Any newly triggered high-risk category requires the existing fresh focused reviewer after the main reviewer clears green/blue; record the focused report or user waiver under the normal verdict contract. If the spec/design no longer covers the changed scope, stop and get the user's design confirmation before the required full review. A full review alone never approves a design change.

## Before starting

Dev-flow mode — verify the state file's **Roles block** (the Reviewer line) before dispatching either group, then select the host:

- Block missing, empty, or the Reviewer line absent → **stop; report "step 5's combined Roles ask was skipped"** — do not dispatch the reviewer, do not re-ask from this skill. Return to new-feature step 5 (the orchestrator asks and writes the picks, then re-invokes). A stop here is a visible gate failure, the same form as the Goal-status gate.
- **Codex:** once the Reviewer line is present, ignore its Claude lane value for model selection and follow `## Model routing`. Validate the Codex config, not the lane syntax or Claude model availability.
- **Claude Code:** a Reviewer lane value (`session`, `claude:<name>`, `cli:<tool>/<model>`) dispatches per `## Model routing`. A malformed lane value → BLOCKED stop-and-ask per [`references/model-routing.md`](../../references/model-routing.md)'s error contract — never treated as unset.
- Missing-block recovery paths (user-confirmed crash-recovery, pre-Roles upgrade mapping) → follow [`references/model-routing.md`](../../references/model-routing.md)'s *Before-starting procedures* section — the only ask-from-here path is a user-confirmed crash recovery; every other missing-block shape stays a stop.

Then read the state file's **Risk tier**:

- Field `low`, `high — <categories>`, or `high — waived by user, <date>` → proceed per the tier: `high` (not waived) requires the focused group below; `low` and waived-high run the main group only.
- Field absent or `_(not asked — step-7 recheck pending)_` → **stop; report "step 7's risk recheck was skipped"** — do not dispatch any reviewer, do not re-run the recheck from this skill. Return to new-feature step 7 (the orchestrator runs the recheck, writes the tier, then re-invokes). Fail-closed: a missing tier is a skipped recheck, never a low.
- Tier `high` (not waived) and **Focused verdict** `_(skipped)_` → stop; report "the focused review was skipped" — the field only ever gets `_(skipped)_` out-of-band (a user dropping the requirement after the fact); a fresh or reset gate round carries `_(pending — run in this gate round)_` and dispatches the focused review as usual after the main reviewer clears green/blue. Absent field on a live high tier → treat as `_(pending — run in this gate round)_` — never as "already covered", and never as `_(not required)_`.

Standalone mode (no state file) → there is no step 5 ask and no risk tier. Codex resolves the optional config directly; Claude Code asks the Reviewer lane (see *Standalone mode* below).

## What you need

- The **spec** at `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md` — source of truth.
- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — task breakdown.
- The **base branch** — usually the state file's Base branch (`dev` by default, or `.dev-flow/config.json`'s `dev_branch`); standalone mode: ask if unclear — reviewing against the wrong base makes the diff meaningless.

## Dispatch the reviewer subagent

Dev-flow mode: check the Reviewer line per `## Before starting` — never ask. Standalone: choose the host-specific route below.

Resolve `main_review` independently through **Per-step reviewer groups** in [`references/model-routing.md`](../../references/model-routing.md). A configured main group overrides the prior route; only when that step is absent, use its existing host and step source: **Codex** `codex_reviewer_model` then session default, per **Codex reviewer model**; **Claude Code** the Roles block's Reviewer lane (standalone: preserve the ask, default `session`). Validate all selected routes before dispatch.

Dispatch every main-group member in a fresh isolated context, concurrently within host limits, with identical frozen review materials and a unique numeric report destination. Queue remaining members without reducing the group. Each member follows the same brief and contracts below; reviewers do not see peer findings before returning. Use the routing reference's isolated-worker brief boundary. A failed dispatch, missing or invalid report, or changed frozen input blocks the whole round. Keep the existing aggregate destination and archive rules for single-reviewer runs; multi-reviewer reports feed that same aggregate destination. When a fix changes reviewed material, rewind through execute and test, then rerun every selected reviewer for each affected review stage against the final changed diff; prior approvals never carry across the fix.

1. **Framing** — "You are a pre-PR reviewer. You have never seen this code before. Review the diff against the spec and plan and return a verdict; do not fix anything."
2. **Base branch + diff command** — `git diff <base>...HEAD` (plus `git log <base>..HEAD --oneline` for commit shape). Read the actual diff, not just commit messages.
3. **Spec and plan paths** — under `docs/features/`; the subagent reads them itself.
4. **The methodology** (R1–R4) — give the subagent the **absolute path** to this skill's `references/clean-code.md` (resolved from the skill's base directory — not repo-relative: in a target repo the file lives in the plugin directory), with the instruction to read it first as the review's checklist; the subagent reads it itself. Paste **R1–R2's and R3's section bodies** (spec coverage / plan coverage / obvious-issue scan) into the dispatch — the reference file carries only the R4 clean-code checklist, not the full methodology — and paste the **verdict contract** (R5) too.
5. **Report contract** — full findings go to each member's unique report destination under `docs/features/.review/<feat-name>/batches/main_review/round-<N>/reviewer-<I>.md` for a multi-member group (gitignored); a single reviewer keeps the existing `review-report.md` path and output contract. The return holds the verdict (`green`/`blue`/`yellow`/`red`), a one-line summary, and counts (e.g. "2 yellow findings"). Detail stays in the report. The orchestrator validates every member report and frozen input, then writes the aggregate to `docs/features/.review/<feat-name>/review-report.md`; preserve individual verdicts, author attribution, and dissent while deduplicating displayed findings.

**Re-review: archive, never overwrite.** If `review-report.md` exists from a prior round, rename it to `review-report-<n>.md` (`-1`, `-2`, …) before dispatching. `review-report.md` is always the latest; each round keeps its record.

Before dispatch, capture the repository root, `git rev-parse HEAD`, the configured base ref, and `git rev-parse <base-ref>`, then inspect uncommitted paths for relevance. If any uncommitted path may affect the review, stop; allow a path only when inspected and proven irrelevant, and record the excluded path and rationale in the report. Never attribute dirty code to a commit. Include the exact repository/head/base values in the brief and report, labeled **Repository**, **Head SHA**, **Base ref**, and **Base SHA**. The report must identify its report path, verdict, and completion time alongside those values; also record whether the review was full or incremental and the prior report path, if any. Record a focused report path or explicit waiver when applicable. At report completion, recheck `HEAD`, base ref/SHA, and relevant working-tree changes; if they changed during the run, invalidate the attempt and rerun. Only after the report exists and the reviewer returns its verdict, write **Review evidence** in the state file with these values and the actual verdict. A dispatch/report failure creates no new evidence and cannot make old clear evidence applicable to the current attempt. A missing field in an older state file means evidence is absent and the gate must be rerun, not assumed clear. A clean local HEAD may be recorded before a PR exists or before a local fix is pushed; this alone says nothing about a later PR's head.

Each reviewer runs R1–R4 and the verdict contract (R5), then returns the verdict. The orchestrator aggregates only after every member completes with a current valid report: any red blocks; otherwise yellow, then blue, then green, preserving all findings and dissent. A passing majority never suppresses a blocker. The orchestrator does **not** re-do the review — it acts on the accepted aggregate.

**Claude Code lane shapes** (Codex uses the native route above):

- **`session` / `claude:<name>`** → Agent-tool dispatch, shape per `## Model routing`'s resolution rule.
- **`cli:<tool>/<model>`** (v1: `cli:codex/<model>`) → thin-driver flow per [`references/model-routing.md`](../../references/model-routing.md): the driver composes the brief + report contract (copied **verbatim at runtime** from this skill's brief/report sections above) into `docs/features/.routing/<feat>/`, runs the CLI (`--sandbox read-only` per the routing doc's sandbox map). The read-only reviewer returns its complete report through output; its driver saves that report verbatim to the member's unique report destination, without editorial judgment. **The relayed payload must carry the verdict + full findings verbatim** — the R5 yellow choice (fix-now vs note-in-PR) must reach the user uncompressed. Availability failures → BLOCKED stop-and-ask, never a silent downgrade.

## Model routing

Host selection, availability checks, and dispatch rules live in [`references/model-routing.md`](../../references/model-routing.md) — the single source. Resolve `main_review` and `focused_review` independently using **Per-step reviewer groups**; an absent step keeps its existing host and step source. **Codex:** for an absent step, resolve `codex_reviewer_model` per **Codex reviewer model** there before every dispatch; record configured models in member reports. **Claude Code:** for an absent step, use the Reviewer lane from the state file's Roles block (dev-flow) or the standalone ask; malformed or unavailable lanes → BLOCKED stop-and-ask. Roles block missing → stop per `## Before starting`; never silently downgrade.

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

On a high (not waived) tier, the act-on-verdict step also covers the focused group's aggregate once every member returns: record it in the state's existing **Focused verdict** field (replacing this round's `_(pending — run in this gate round)_`), then apply the same R5 handling — every member of both required groups must complete, and both aggregates must clear. Never reuse an earlier round's focused value.

## Focused review (high risk tier only)

Triggers when the state's **Risk tier** is `high — <categories>` (not waived), after the main group's R5 handling clears: green clears directly; blue and yellow require the user's recorded note-in-PR choice before focused dispatch. Either fix-now choice rewinds before focused dispatch. Main red also rewinds. **Serial placement, for its real trade-off:** serial saves the tokens a parallel focused verdict would burn when a main-review yellow/red rewinds to step 5 and invalidates it; parallel saves wall-clock but its verdict gets thrown away on rewind. The focused group always scans the final diff.

**Dispatch** — independently resolve `focused_review` through **Per-step reviewer groups** in [`references/model-routing.md`](../../references/model-routing.md). A configured focused group overrides its prior route; only when that step is absent use the existing source (Codex `codex_reviewer_model` then session default, per **Codex reviewer model**; Claude Code the state's Reviewer lane). Re-resolve and validate all members before dispatch. Dispatch every member in a fresh isolated context with the same current diff, the same combined category brief, and a unique numeric report destination; run concurrently within host limits and queue the rest. Every member uses the same fresh-eyes framing: "You are a focused risk reviewer. You have never seen this code before. Deep-scan the diff for your assigned risk categories and return a verdict; do not fix anything." Give each the base branch + diff command, spec/plan paths, R5 verdict contract, and the **combined brief** — one brief covering all triggered categories:

- **destructive-operations** → blast radius of each destructive command, backup paths, recovery story.
- **auth-permissions** → permission boundaries deeper than R3's obvious-smell scan: auth spine, middleware, permission checks, session handling.
- **executable-code** → each newly introduced privileged/triggered execution path: what triggers it, what it can do, who can reach it.
- **blast-radius** → whether the diff's breadth is justified by the spec, or scope creep wearing a costume.

**Any number of triggered categories → still one focused group** with the combined brief sent identically to each configured reviewer; categories do not multiply the reviewer count. When >2 categories trigger, add a one-line user note (a wide risk surface is worth their attention — it is not a plan defect and there is no bounce). Deep-scan only the triggered categories; do not redo R1–R4 or the independent main review.

**Report + verdict** — same R5 contract and color-coded report format. For a multi-member focused group, each member writes to `docs/features/.review/<feat-name>/batches/focused_review/round-<N>/reviewer-<I>.md`; a single reviewer keeps the existing individual report path. After all reports and frozen inputs validate, aggregate into the existing `docs/features/.review/<feat-name>/review-report-focused.md` (gitignored; same archive rules — never shares the main report's path). The return holds the verdict + one-line summary + counts. The orchestrator records the current aggregate in the state's **Focused verdict** field, then acts: **hard gate — every member of both required groups must complete and both aggregates must clear.** Any red → red-loop rewind to step 5; yellow → the same fix-now / note-in-PR prompt; green/blue → advance to step 8.

## Standalone mode (outside dev-flow)

No state file: ask for the base branch (or infer from `git merge-base`), read the spec/plan if the user points to them, and resolve only the `main_review` group. An absent step keeps the existing standalone fallback: **Codex** resolves the optional config per `## Model routing`; **Claude Code** asks for the Reviewer lane, default `session`. Skip the gate. Aggregate every member's report and verdict; the user decides next steps. Risk-tier is a dev-flow gate feature (state file + plan Risk lines) — standalone review has no focused group, no focused risk tier, and the user owns their review depth.

Report home without a feat-name: the **branch name** — `docs/features/.review/<branch-name>/review-report.md` (slashes flattened to dashes: `feat/9-fix-crash` → `.review/feat-9-fix-crash/`). Archive existing reports per the re-review rule.

## What not to do

- **Don't re-do the review after the verdict** — trust it and act.
- **Don't let the reviewer fix things** — a reviewer that starts editing has stopped reviewing.
- **Don't open the PR** — that's step 9, and step 10's merge is manual.
- **Don't run the test suite** — that's `dev-flow:test`'s job (step 6); review trusts step 6's green.
- **Don't pre-judge** — flag a question as a question, not a verdict — and don't review against the wrong base.
