---
name: test
description: Use to run a fresh-subagent test gate on a feat or fix branch — full suite + lint plus a test-honesty scan (tests that assert nothing, mock the thing under test, tautologies, pass regardless of code). This is dev-flow step 6 (between execute and review). Spawns a fresh tester subagent (no author bias) that runs the suite itself and returns a green/red verdict; red sends the work back to execute. Also runs standalone on any branch ("test this branch", "run the test gate"). Does not review code — that's dev-flow:review (step 7).
---

# Test

A pre-review test gate: is the suite green and are the tests honest? It does **not** review code — that's `dev-flow:review`. Runs against the branch's diff and the repo's test + lint commands.

## Gate (dev-flow, between step 5 and 7)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `execute`. Don't advance the status here — step 6 in the orchestrator sets `test`. Wrong status → stop, tell the user which step to run. No state file (standalone) → see *Standalone mode*.

## Before starting

Dev-flow mode — read the state file's **Roles block** (the Tester line) before dispatching the tester:

- Block has a Tester lane value (`session`, `claude:<name>`, `cli:<tool>/<model>`) → dispatch on it per `## Model routing`.
- Block missing, empty, or the Tester line absent → **stop; report "step 5's combined Roles ask was skipped"** — do not dispatch the tester, do not re-ask from this skill. Return to new-feature step 5 (the orchestrator asks and writes the picks, then re-invokes). A stop here is a visible gate failure, the same form as the Goal-status gate.
- Malformed lane value → BLOCKED stop-and-ask per `references/model-routing.md`'s error contract — never treated as unset.
- Missing-block recovery paths (user-confirmed crash-recovery, pre-Roles upgrade mapping) → follow `references/model-routing.md`'s *Before-starting procedures* section — the only ask-from-here path is a user-confirmed crash recovery; every other missing-block shape stays a stop.

Standalone mode (no state file) → there is no step 6; ask the Tester lane yourself (see *Standalone mode* below).

## What you need

- The **plan** at `docs/features/plans/YYYY-MM-DD-<feat-name>.md` — what the work claims to do.
- The **base branch** — from the state file's **Base branch**; ask if unclear.
- The repo's **test + lint commands** (e.g. `flutter test`, `pytest`, `npm test`, `cargo test`).

## The tester lane (dev-flow mode: read, don't ask)

In dev-flow mode the orchestrator already asked the combined Roles ask at step 5 and wrote the picks to the state file's Roles block — read the Tester line; don't re-ask. A missing block or line is a skipped ask: stop and report it per `## Before starting` — never fill it in from here. In standalone mode ask the user, default `session`.

## Dispatch the tester subagent

Spawn **one** fresh tester subagent on the Tester lane. Never run the gate inline — fresh eyes are the point; the author of the work biases its own test review.

**Lane shapes:**

- **`session` / `claude:<name>`** → Agent-tool dispatch, shape per `## Model routing`'s resolution rule.
- **`cli:<tool>/<model>`** (v1: `cli:codex/<model>`) → thin-driver flow per `references/model-routing.md`: the driver composes the brief + report contract (copied **verbatim at runtime** from this skill's brief/report sections above) into `docs/features/.routing/<feat>/`, runs the CLI (`--sandbox workspace-write` per the routing doc's sandbox map), and the external model writes its full report to the same `docs/features/.test/<feat-name>/test-report.md` path. **Known limitation:** a suite needing network installs fails under the sandbox — a known BLOCKED with a resume hint, never a false red. Availability failures → BLOCKED stop-and-ask, never a silent downgrade.

The brief gives the subagent:

1. **Framing:** "You are a test gate. You have never seen this code before. Run the suite and scan test honesty; do not fix anything."
2. **The diff:** base branch + `git diff <base>...HEAD` (plus `git log <base>..HEAD --oneline` for the commit list).
3. The **plan path** — what the work claims to deliver.
4. The repo's **test + lint commands** — the subagent runs them itself.
5. The **checklist** (both checks below) and the **verdict contract** (green / red only).
6. The **report contract:** full findings written to `docs/features/.test/<feat-name>/test-report.md` (gitignored); the return message holds only the verdict (`green`/`red`), a one-line summary, and counts (tests passed/failed, findings). **Re-run: archive, never overwrite** — if `test-report.md` exists, rename it to `test-report-<n>.md` (next free number) before writing the new one.

Never dispatch more than one tester at a time.

## Model routing

Lane semantics, availability checks, and the thin-driver flow live in `references/model-routing.md` — the single source; this skill does not re-derive them. This skill's Tester line comes from the state file's Roles block (dev-flow mode) or the standalone ask. Roles block missing → stop per `## Before starting`; malformed lane → BLOCKED stop-and-ask; any lane unavailable → BLOCKED stop-and-ask, never a silent downgrade.

## The test gate (run by the tester subagent)

The report is color-coded, same conventions as the review report:

- Header: 🟢 **GREEN** or 🔴 **RED** verdict.
- Sections: 🟩 **1. Test + lint gate** (pass/fail per command), 🟨 **2. Test honesty scan** (numbered findings, each with `file:line` + one-line problem).

The two checks:

1. **Test + lint gate (hard).** Run the full test suite and lint. Any failure or lint warning → **stop**, report, return `red`. No test/lint command exists in the repo → say so in the report and proceed to the honesty scan (a docs-only repo passes this check by noting the absence).
2. **Test honesty scan.** Read the diff's new/changed tests for:
   - **Asserts nothing** — a test with no meaningful assertion.
   - **Mocks the thing under test** — the test mocks the very function it claims to verify.
   - **Tautological** — asserts the mock's own return value back.
   - **Passes regardless of code** — would still pass with the feature deleted.
   
   Each finding: `file:line` + one-line problem. **A dishonest test is `red`** — the suite lying about its coverage is a blocker, same severity as a red suite.

**Verdict:** `green` (suite green, tests honest) or `red` (anything red or dishonest). No yellow — a suite is green or it isn't; honesty findings are blocking or they aren't.

## Act on the verdict (orchestrator)

- **Green** → update the state file's **Last verification** from the tester's result; hand back to the orchestrator for step 7 (review).
- **Red** → re-set **Goal status** to `execute` (red-loop rewind) — with the `Status since:` timestamp (third write of the status-transition protocol); surface the blockers; return to step 5 with the findings. Fix, then re-run test with a **fresh tester subagent** (not the same one).

Keep the report file. Never delete or overwrite — archive per the re-run rule so the history of red→green loops stays readable.

## Standalone mode (outside dev-flow)

No state file → ask for the base branch (or infer via `git merge-base <default>...HEAD`), **ask for the Tester lane** (no Roles block exists to read; default: `session`), and dispatch the same subagent. Report home: `docs/features/.test/<branch-name>/test-report.md` (slashes flattened to dashes).

## What not to do

- **Don't run the gate inline** — always dispatch a fresh tester subagent; the author biases their own test review.
- **Don't re-run the gate after the verdict** — act on it; a re-run is for after fixes.
- **Don't let the tester fix anything** — it reports; the fix loop is step 5's.
- **Don't skip the suite** — the honesty scan supplements the suite, never replaces it.
- **Don't test against the wrong base** — verify the diff is actually this branch's work.
- **Don't review code** — spec coverage, bugs, maintainability are `dev-flow:review` (step 7).
- **Don't return yellow** (the green/red-only verdict contract above).