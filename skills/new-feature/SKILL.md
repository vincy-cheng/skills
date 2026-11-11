---
name: new-feature
description: Start or resume a feature or fix through the complete dev-flow pipeline. Use when asked to build a feature, implement a change, or resume a dev-flow run.
---

# New feature or fix — full workflow

## Output style

Before writing responses or human-readable files, load `references/output-style.md` from the plugin root (the directory containing `references/`, not the target repository root). Pass its actual contents to every subagent you dispatch, including isolated reviewers. User requirements and specific output contracts take precedence.

> **Single source of truth.** This file carries the full workflow — gate table, state-file template, resume rules, preflight, commit guard, and every step definition. Command surfaces (`commands/new-feature.md` and any host's equivalent entry point) are thin wrappers that delegate here; don't duplicate workflow content in a wrapper.

Drive the feature or fix in the user's request through all steps, in order. Do not skip steps because the request seems simple. Treat the user's message as the input brief or resume selector.

Steps in four phases — 11 total:

```
Plan   : 1 brainstorm → 2 spec → 3 plan → 4 create issue
Build  : 5 execute (TDD)
Verify : 6 test → 7 review → 8 doc-fix
Ship   : 9 PR → 10 merge (manual) → 11 close-out
```

Run each step before the next. Pause at the natural checkpoints (after spec, after plan, after issue draft, before PR). State which step you're on as you begin it.

**Resume:** if the user asks to resume, provides only a feat-name, or gives no new feature brief, go to **Resume** below and discover/continue existing work before starting anything fresh.

## Context reuse

Load only the current step’s required skills and references. Reuse unchanged guidance that is already in context. Reload a skill or reference when it changes, is unavailable, was lost after compaction, or its version cannot be established. Cached guidance never replaces live state reads, authorization checks, or evidence identity checks.

In the existing role-selection step, recommend inline execution for small, tightly coupled work. Preserve saved roles, models, and execution modes.

## Skills — all in-house

Runs its own skills for every step: `dev-flow:brainstorm` (step 1, which writes the spec), `dev-flow:plan` (step 3), `dev-flow:execute-tasks` (step 5, which invokes `dev-flow:tdd` per task), `dev-flow:test`, `dev-flow:review`, `dev-flow:doc-fix`, `dev-flow:open-pr`, `dev-flow:create-github-issue`, and `dev-flow:commit`. No external plugin dependencies — no step invokes a `superpowers:*` skill or any other plugin's skills.

**Artifact rules (apply to every sub-skill):**

- Before writing any file for this run, verify the target is under `docs/features/` — never `docs/superpowers/` or any other workspace path. If an earlier skill version wrote there, move the file.
- Never commit specs, plans, or state files (see *Commit guard*). Design docs and state are dev-flow-local only.
- A sub-skill's handoff never advances, skips, or reorders steps — see *The hard gate*.

## The hard gate

Steps 1 and 3 invoke dev-flow's own skills (brainstorm, plan) whose terminal states are their artifacts (spec, plan) — but a sub-skill left unchecked **will** skip or reorder this workflow via its own "next step" instructions. The gate prevents it **structurally**: the state file's **Goal status** is the only thing that advances a step.

**Gate check — run at the start of every step:**
1. Read `docs/features/.feature-states/<feat-name>.state.md`.
2. Compare **Goal status** to the status this step requires (table below).
3. Match → proceed. No match → STOP; tell the user the current status and the step it maps to, and resume from there. Do **not** do the current step's work.
4. Set **Goal status** to this step's status *before* the work, so a crash/resume lands back on this step. **Steps 4 and 10 are exceptions:** step 4 defers its `issue` transition until the plan-review read-gate passes; `dev-flow:create-github-issue` owns that transition for both orchestrated and direct in-flow invocation. On a failed pass, step 4 rewinds to `spec` as described there. Step 10 keeps `pr-review` while it reads remote state and performs checks; transition to `merged` only after the remote PR state confirms it is merged.
   A status change is **three writes, done together in one breath**: the state file's Goal status, the index row (see *Index file* — new status + timestamp, re-sort newest-first), and the state file's **`Status since:`** field — the timestamp of the status change, the timing source for session-help displays. One without the others is an incomplete step. Step 1 adds the row; later steps update it.

Lifecycle: `brainstorm` → `spec` → `planning` → `issue` → `execute` → `test` → `review` → `doc-fix` → `pr-review` → `merged` → `done`. A step runs only on the immediately preceding status and advances only to the next when done. `test` is the fresh-subagent test gate (step 6); `review` the judgment review (step 7); `doc-fix` the pre-PR doc drift gate (step 8). `merged` means "shipped, close-out pending" — the crash-resume safety net between "user confirmed merge" and "close-out complete"; `done` means fully closed.

| Step | Requires incoming | Sets |
|------|------------------|------|
| 1 brainstorm | _(fresh / no state file)_ | `brainstorm` |
| 2 spec | `brainstorm` | `spec` |
| 3 plan | `spec` | `planning` |
| 4 issue | `planning` | `issue` |
| 5 execute | `issue` | `execute` |
| 6 test | `execute` | `test` |
| 7 review | `test` | `review` |
| 8 doc-fix | `review` | `doc-fix` |
| 9 PR | `doc-fix` | `pr-review` |
| 10 PR check / merge | `pr-review` | `pr-review` while open or unresolved; `merged` only after remote merge confirmation |
| 11 close-out | `merged` | `done` |

**Red-loop rewind:** steps 6 (red), 7 (red), and 8 (STOP) hand back to step 5 execute — but step 5's gate requires incoming `issue`. Rule: when a Verify-phase step sends work back, the orchestrator re-sets **Goal status** to `execute` first; step 5 treats `execute` as a valid re-entry (fix-continue — Tasks stay as-is, only the findings' fixes are new work).

**Sub-skill handoffs — ignore them; return to the next dev-flow step:**
- `dev-flow:brainstorm` finishes → **step 2 (spec)**. Its terminal state is the approved spec — it has no handoff.
- `dev-flow:plan` finishes → **step 4 (create issue)**. The issue must exist first (the branch is named `feat/<n>-<name>` or `fix/<n>-<name>`).
- Gate check fails → STOP and resume from the status the state file names. Don't "helpfully" follow the sub-skill.

The state file is the single source of truth for "what step am I on." On any doubt or ambiguity: run the gate check.

## State files

Two gitignored files under `docs/features/.feature-states/` (the whole `docs/features/` folder is gitignored — never commit; add to `.gitignore` on first use if missing):

- **Per-feature state file** — `<feat-name>.state.md`. `<feat-name>` is kebab-case, matching spec/plan filenames and the branch name. Created in step 1; updated on every status change. The source of truth.
- **Index file** — `.state.md`. Mirrors all runs so you can see the current/last one at a glance. A convenience, not a second source of truth; if it disagrees with the state files, rebuild it from them.

### Per-feature state file

```markdown
# <feat-name> — dev-flow state

- **Created:** YYYY-MM-DD HH:MM±HH:MM
- **Updated:** YYYY-MM-DD HH:MM±HH:MM
- **Status since:** YYYY-MM-DD HH:MM±HH:MM
- **Base branch:** <branch>
- **Target branch:** <branch>
- **Goal status:** <status>
- **Kind:** feature | fix
- **Last verification:** YYYY-MM-DD HH:MM±HH:MM — <test cmd> <passed|failed>, <lint cmd> <clean|warnings>
- **Risk tier:** <low | high — <categories> | high — waived by user, YYYY-MM-DD | _(not asked — step-7 recheck pending)_>
- **Focused verdict:** <green|blue|yellow|red | _(not required)_ | _(pending — run in this gate round)_ | _(skipped)_>
- **Codex implementer model:** <optional — omit until the run choice is confirmed>
- **Implementer context:** <shared | per-task | not-used — omit until the run choice is confirmed; legacy subagent runs read as per-task>

## Verification evidence

- **Test evidence:** Repository: <repo>; Head SHA: <sha>; Base ref: <ref>; Base SHA: <sha>; Report path: <path>; Verdict: <green|red>; Time: <timestamp>
- **Review evidence:** Repository: <repo>; Head SHA: <sha>; Base ref: <ref>; Base SHA: <sha>; Report path: <path>; Verdict: <green|blue|yellow|red>; Time: <timestamp>; Scope: <full|incremental>; Previous report: <path|_(none)_>; Focused report/waiver: <path|waiver|_(not applicable)_>

## PR check

- Repository: <repo>; PR: <#NN>; URL: <url>; Head SHA: <sha>; Base ref: <ref>; Base SHA: <sha>; Checked at: <timestamp>; Result: <passed|pending|needs-fix>; Reason: <summary>; Report: <path>

## Roles

- Implementer: <inline | session | claude:<name> | cli:<tool>/<model>>
- Tester: <session | claude:<name> | cli:<tool>/<model>>
- Reviewer: <session | claude:<name> | cli:<tool>/<model>>

## Tasks
- [ ] <task description>

## References
- Overview: <path or _(none)_>
- Spec: docs/features/specs/YYYY-MM-DD-<feat-name>-design.md
- Plan: <path or _(pending)_>
- Issue: <#NN or _(pending)_>
- PR: <#NN or _(pending)_>
```

Field rules:
- **Created** — set once in step 1, never changes. Carries local time + UTC offset (e.g. `2026-09-10 14:45+08:00`), so a reader never has to guess the zone.
- **Updated** — current timestamp on *every* write. Local time + UTC offset (e.g. `2026-09-10 14:45+08:00`).
- **Goal status** — the gate's input; set to the current step *before* the work.
- **Status since** — the timestamp of the most recent Goal-status change, rewritten on every flip (all three writes in one breath). Local time + UTC offset. The timing source for duration displays; old state files without the field degrade gracefully (no duration shown).
- **Kind** — `feature` or `fix`, set in step 1 from intent. Drives the branch prefix and issue framing. Ambiguous → ask; default `feature`.
- **Last verification** — most recent test + lint result during execute (the repo's commands). The resume signal: "was it green when I stopped?" `_(not run yet)_` until first run.
- **Verification evidence** — test and review results are reusable only for the exact repository, `HEAD` SHA, base ref, and base SHA recorded with their report, and only when the checked changes were attributed to that HEAD. Before dispatch, capture those values and inspect uncommitted paths for relevance. If any uncommitted path may affect the verification, stop; allow an uncommitted path only when it is inspected and proven irrelevant, and record the excluded path and rationale in the report. Never attribute dirty code to a commit. At report completion, recheck `HEAD`, base ref/SHA, and relevant working-tree changes; if they changed during the run, invalidate the attempt and rerun. Record evidence only after the report exists and its verdict is returned; preserve the actual verdict, so a failed check can never be recorded as passing. A dispatch/report failure creates no new evidence and cannot make old green evidence applicable to the current attempt. Old state files without evidence have missing evidence, not an implied pass: rerun the relevant gate and then write the fields. Steps 6 and 7 may record local-HEAD evidence before PR creation or before local fixes are pushed; Step 10 will decide whether evidence matches the PR. Keep **Last verification** as the human-readable summary, not a substitute for these fields.
- **Roles block (`## Roles`)** — three lines: Implementer / Tester / Reviewer, each a lane value from `references/model-routing.md` (`inline` + the three lanes for Implementer; three lanes for Tester/Reviewer). Asked **once, combined**, by the orchestrator at step 5 **before invoking `dev-flow:execute-tasks`** (one prompt covering all three roles, config-seeded — see step 5). The block missing or empty in dev-flow mode = the step-5 Roles ask was skipped (or its write failed) → execute-tasks'/test's/review's entry read-gates stop on it; the **write is the only record of the ask** — an ask without a completed write doesn't count. On resume, read the stored picks and proceed; do not re-ask. **Upgrade mapping (old state files, read-only — never migrated on disk):** an old `Implementer mode: inline` → Implementer `inline`; old `subagent` with no model → `session`; old `subagent` + model name → `claude:<name>`; an old `Verifier model` pick → the Tester and Reviewer lines (shared, as it was used). A block with any line malformed (unknown lane syntax) → BLOCKED stop-and-ask per the routing doc's error contract — never treated as unset. Codex ignores the Reviewer line's lane value for model selection, per the routing doc's **Codex reviewer model** rules; the Roles-presence gate and implementer/tester routing remain unchanged.
- Red-team has **no** Roles line — it is config-only. Claude Code reads `roles.reviewer`; Codex reads `codex_reviewer_model` for all four reviewer paths. Host precedence and validation live in `references/model-routing.md` (**Codex reviewer model**); see the brainstorm skill's `## Model routing`.
- **Risk tier** — written by the orchestrator at step-7 entry (the risk recheck's output; see the step 7 gate line). `low` or `high — <categories>`, or `high — waived by user, YYYY-MM-DD` when the user waived the focused review — the waiver is the field's value, recorded honestly, not a separate field. `_(not asked — step-7 recheck pending)_` is the creation default, so a missing recheck is distinguishable from a decided low. Fail-closed: the review read-gate treats an absent/not-run field as a skipped recheck (stop + report), never as low. A state file predating this field has no Risk tier line: on resume, the review read-gate stops and returns to step 7, which re-runs the recheck and writes the tier — the recheck is cheap and resume-safe; no low-with-warning branch.
- **Focused verdict** — the focused reviewer's verdict (green/blue/yellow/red), written by the review skill when a focused review runs; `_(not required)_` when the tier is low or waived. When step 7 writes a live (not waived) `high` tier, it also writes `_(pending — run in this gate round)_` in the same breath — the field must never stay placeholder on a live high tier, so the review read-gate distinguishes "this round's focused review pending" from "skipped": only `_(skipped)_` (written only when the user drops the requirement out-of-band after the tier was set) stops the gate with "the focused review was skipped"; an absent or placeholder field on a live high tier is treated as pending-this-round, dispatching as usual — never as "already covered". On a resumed pre-fix state file the same rule applies after step 7 re-writes the Risk tier.
- **Codex implementer model** — optional field outside the Roles block. Omit it until step 5 confirms the run choice; its grammar, host boundaries, and validation live in `references/model-routing.md` (**Codex implementer model**). On a confirmed Codex run, record the exact selected model, `_(session default)_`, `_(not used — inline)_`, or `_(not used — cli)_`. A missing field denotes an older or unconfirmed run; never change mode/model from it or claim a saved model. A change to the recorded choice requires the user's explicit request.
- **Implementer context** — optional field outside the Roles block, next to **Codex implementer model**. Records the confirmed context lifecycle: `shared`, `per-task`, or `not-used` (inline). Omit it until the run choice is confirmed; grammar and host capability gate live in `references/model-routing.md` (**Implementer context**). A field missing on a legacy subagent run reads as `per-task` (that was the actual shape — read-only, never migrated on disk). An unknown value **stops** (BLOCKED stop-and-ask) — never treated as unselected. A saved choice is preferred over any later default; resume and repair read the stored pick and do not re-ask; a change requires the user's explicit request.
- **Tasks** — mirrors the plan's task list as `- [ ]` / `- [x]`; flip on every status change. Live progress; the plan doc is static design. Annotate a task `— ⚠ test failing: <reason>` only when its test exists and is currently red; clear when green. Don't annotate passing/pending tasks — a `[x]` already means its test passed.
- **References** — overview (step 1, only when the run came from a decomposed roadmap — else `_(none)_`), spec (step 2), plan (step 3), issue (step 4), PR (step 9). Test (step 6) and review (step 7) add no reference. Replace `_(pending)_` with the real value when it exists.

### Index file

```markdown
# dev-flow runs

| Feat-name | Kind | Status | Issue | Updated | Branch |
|-----------|------|--------|-------|---------|--------|
| <feat-name> | feature | execute | — | YYYY-MM-DD HH:MM±HH:MM | feat/42-x |
| <feat-name> | fix | done | #17 | YYYY-MM-DD HH:MM±HH:MM | fix/17-y |
```

One row per feat; newest **Updated** first (re-sort on every write). The top non-`done` row is the current run; `done` rows stay as history — don't delete them. The **Issue** column is `—` until step 4 creates the issue, then `#NN` for the row's life (set in step 4's two-writes-in-one-breath, never changes after). Maintained alongside the per-feature state file on every status change (and during execute on every task/test, via `execute-tasks`). Stale-row cleanup: if a feat's state file is gone, drop its row. Never invent rows — the state files are the source of truth; the index only mirrors them.

## Resume

You may not remember the feat-name you were on. The index file records it — open `docs/features/.feature-states/.state.md` and the current/last run is the top non-`done` row.

- **No feature brief in the user's message (or an explicit "resume"):** read the index; present the active rows numbered; resume the topmost unless the user picks another. Index missing → fall back to scanning `docs/features/.feature-states/*.state.md`, sort by **Updated**, rebuild the index. Zero state files → start fresh from step 1.
- **Feat-name given in the user's message:** use it directly. State file missing for it → tell the user; don't silently start fresh.

Then **run the gate check**: read that feat's state file, jump to the step matching **Goal status**, reload referenced spec/plan/issue, continue. Don't restart from brainstorm. `test` → re-run `dev-flow:test`. `review` → re-run `dev-flow:review`. `doc-fix` → re-run step 8 via `dev-flow:doc-fix` (idempotent: re-scan for drift, re-apply). `pr-review` → read the recorded PR identity and run Step 10 directly; if identity is missing, locate and verify the existing PR from the recorded repository, branch, and target before continuing. Never create a replacement PR during resume. `merged` → run step 11 (close-out).

Only `done` is "finished" — `merged` still has close-out pending. Treat `done` rows as history; resume any non-`done` row.

**Resume restrictions:** read the applicable user and repository restrictions when action is actually required. They apply to scripts, CLIs, and APIs as well; never route a prohibited `git push`, remote-branch change, or issue action through another tool. If the resumed step is normally interactive or publishes state, state what can safely proceed and what remains blocked.

## Preflight — `docs/features/` is gitignored

Run before step 1, every invocation. The folder holds local-only artifacts and must never reach the remote.

```bash
git check-ignore -q docs/features/ || echo "NOT_IGNORED"
```

`NOT_IGNORED` → add it:
```bash
printf 'docs/features/\n' >> .gitignore
```

If `docs/features/` is already tracked, surface it and stop — don't silently `git rm`. Ask the user. Once gitignored, continue.

## Commit guard — never commit specs, plans, or state

Three local-only artifacts under `docs/features/` (spec, plan, state) must never be committed or pushed. The preflight (run every invocation) already guarantees the gitignore; two checks carry the rest:

- Stage explicitly (`git add <specific files>`), never `git add -A` / `git add .` — guards against leaking if gitignore drifts.
- Before pushing in step 9, confirm `git status --porcelain docs/features/` is empty. If not, stop and fix.

## Step 1 — Brainstorm
**Gate:** fresh start → set `brainstorm`. Create the state file (default base `dev`, target `dev` — target is the PR destination; for `main`-only repos, both are the default branch; when `.dev-flow/config.json` exists, its `dev_branch` is the default for both — malformed config → warn and ASK, never silently substitute `dev`) and add the index row. Set **Kind** from intent (ask if ambiguous). Invoke `dev-flow:brainstorm` to explore intent, requirements, design — it owns the interview (problem, kind, scope, success), idea-folder ingestion, and the design dialogue. Don't write code. The skill's terminal state is the approved spec under `docs/features/specs/` — it has no handoff; advance to step 2.

If the user's request references an idea folder, the skill ingests its docs as the established brief and the run records the folder path in References. If the run is seeded from an overview spec (brainstorm's decomposition fired on a prior run), the state file's References record the Overview path at creation.

## Step 2 — Spec (local only)
**Gate:** `brainstorm` → set `spec`. Carry brainstorming's output forward; don't re-derive. The spec is written by `dev-flow:brainstorm` at `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md` — verify it exists, add the path to References, show the user. Before step 3, validate `## Viability pass`: architectural work needs a complete current `red_team` batch under **Per-step reviewer groups** and **Review batches** in `references/model-routing.md`, including selected routes, reviewed material identity, a report and explicit completion from each reviewer, findings/handling, and aggregate. A heading, claimed dispatch, missing report, incomplete or stale batch fails. Repair missing or invalid evidence through brainstorm and revalidate. For a spec confirmed to predate this requirement, ask whether to complete the review or use the legacy exception; record the user's explicit choice in `## Viability pass`. Absence alone never establishes legacy status or permission. Keep Goal status at `spec` until validation or the recorded exception is complete. Bounded work retains its self-check and spike behavior is unchanged. On every resume at `spec`, repeat this validation before invoking step 3; status alone does not establish readiness. (The preflight already gitignores the spec.)

## Step 3 — Plan
**Gate:** incoming `spec`. While Goal status remains `spec`, confirm Step 2's current viability evidence or its explicit recorded legacy exception; missing, stale, or incomplete evidence returns to Step 2 for repair and keeps status at `spec`. Only then, after this check succeeds, set `planning` per the gate table and invoke `dev-flow:plan`. Never infer readiness from `spec` status. **Follow the plan skill** — the plan is generated there, not hand-authored. It saves the plan to `docs/features/plans/YYYY-MM-DD-<feat-name>.md` (its own convention — no override needed), produces the contract-complete sections (overview, Global Constraints, Flow Chart, File Structure, Tasks with per-task files and TDD shape), classifies plan review depth by size, and runs `## Plan review pass` (eligible small work can use an author self-check, while ordinary or poorly classified work keeps an independent `plan_review` group). The shared route and batch evidence rules live in `references/model-routing.md`. Recheck the classification before approval when tasks or scope change, and when repair adds work. The plan has no handoff. Its terminal state is the approved plan **carrying its complete current `## Plan review pass` section**. Copy the task list into the state file's Tasks **only after the pass is final** (rework rounds revise the plan; an early copy desyncs); add the plan path to References. Advance to step 4.

## Step 4 — Create issue
**Gate:** incoming `planning`. **Do not set `issue` at step entry.** Invoke `dev-flow:create-github-issue`, which checks the plan-review pass before advancing status. If the pass is missing, its classification or self-check eligibility is unsupported, or it ends `needs-rework`, stop; `dev-flow:create-github-issue` rewinds the status mirror to `spec` by updating Goal status in the state file, the index row and Updated timestamp, and `Status since:` together. This returns resume to step 3 to revise or complete the pass; it cannot jump to execution. The sub-skill owns this rewind for direct and orchestrated calls, so do not repeat it here. A plan predating the pass requirement follows the legacy choice in the sub-skill. Once its read-gate passes, the sub-skill advances the run to `issue` and drafts the issue from the spec + plan. Draft → user confirms → publish with `gh`; user picks labels. Offer a `feat/<n>-<name>` (or `fix/<n>-<name>`) branch off the state file's Base branch; update the state file's base branch and record the issue number in References.

## Step 5 — Execute tasks (TDD)
**Gate:** `issue` → set `execute`. **Before invoking `dev-flow:execute-tasks`: the combined Roles ask.** One prompt covering all three roles — Implementer, Tester, Reviewer — each line pre-filled and overridable in the same turn. When prior `## Task outcome` sections (recorded per `references/task-outcomes.md`) support a pick, tag the recommendation `[evidence: …]` with a one-line basis; no supporting evidence keeps the `[recommended]` tag — recommend-only, the user confirms every pick: config `.dev-flow/config.json` `roles` → pre-fill that value tagged `[config]`; no config → `[recommended]` defaults (Implementer from the plan's task shape — mechanical/well-specified tasks lean `inline`, multi-file integration leans a subagent lane; Tester/Reviewer `session`). On Codex, read optional `codex_implementer_model` and present execution mode and implementation model together: a configured model prefills a native implementation subagent option; if `roles.implementer` expresses a conflicting mode, show the conflict and require explicit confirmation (never switch silently), and explicit inline/CLI choices acknowledge that the native setting is unused. The same ask covers the **Implementer context** pick — `shared` / `per-task` / `not-used` — confirmed together with lane and model: recommend from the plan signal with trade-offs explained (a pinned lightweight model with related tasks leans `shared`; no model difference with tightly-coupled tasks leans `inline`; isolation needs lean `per-task`), but the user chooses — never pick or switch the model/execution shape silently for them. Persist the confirmed model, session default, or unused marker with the Roles picks, and the confirmed context pick next to them. Write them to the state file's **Roles block**, **Codex implementer model** field, and **Implementer context** field (lane/value grammar per `references/model-routing.md`), then resolve that run choice through the shared validation contracts (**Codex implementer model**, **Implementer context**) before task work. Roles block not written → do not invoke execute-tasks; the ask happens once here — execute-tasks, test, and review read the block from the state file and do not re-ask (dev-flow mode). Then invoke `dev-flow:execute-tasks` to work the plan task by task with TDD (its RED step follows `dev-flow:tdd`), dispatching each per the Implementer line's lane and the Implementer context pick, committing per task via `dev-flow:commit` and updating the state file on every subtask start/complete and every test run. Either way, all artifacts stay under `docs/features/` (no `.superpowers/` workspace). When all tasks are `[x]` and the suite is green, advance to step 6.

## Step 6 — Test (fresh subagent)
**Gate:** `execute` → set `test`. **No model ask here** — the Tester's lane was settled by the step-5 combined Roles ask. Roles block missing/empty → stop: return to step 5 to complete the ask (the entry read-gate in `dev-flow:test` also stops on it). Then invoke `dev-flow:test`: it reads the Roles block silently and dispatches a fresh tester subagent on the Tester lane — the tester runs the full test suite + lint (hard gate) and a test-honesty scan (per the test skill's pattern list), writes a color-coded report to `docs/features/.test/<feat-name>/test-report.md`, and returns **green / red**:
- **Green** → update the state file's **Last verification** from the tester's result; advance to step 7.
- **Red** → do not advance; red-loop rewind (per *The hard gate*) back to step 5 with the findings.

## Step 7 — Review (fresh subagent)
**Gate:** `test` → set `review`. **Before invoking `dev-flow:review`, run the risk recheck** — (a) read the plan's per-task `Risk:` lines; (b) probe the executed `git diff <base>...HEAD` against the four category bars (illustrative greps as hints, not gates: destructive command strings like `push --force`/`reset --hard`/`DROP`-shaped SQL, CI/workflow file changes, schema migrations, auth-path files; categories, not a list). **Signal combination is escalation-only:** a plan tag `high` → high; a probe hits a category bar → high; both silent → low — the recheck never downgrades a plan high to low. Write the result to the state file's **Risk tier** field (`low` or `high — <categories>`); on a `high` tier, write **Focused verdict** `_(pending — run in this gate round)_` in the same breath (waived-high writes `_(not required)_`). **Show the tier to the user with a waiver hook**: on a high tier, they may waive the focused review — record `high — waived by user, YYYY-MM-DD` in the field and proceed without the focused reviewer; a waiver is honest state, not a bypass of the field. **Risk tier not written → do not invoke `dev-flow:review` — do not dispatch the reviewer before the tier is in the state file.** Then invoke `dev-flow:review`. **No model ask here** — the Roles block was settled at step 5. Claude Code uses the Reviewer lane. Codex ignores that lane and resolves optional `codex_reviewer_model` per **Codex reviewer model** in `references/model-routing.md`, validating before native dispatch. It keeps the Roles-presence gate and dispatches a fresh reviewer subagent: spec coverage, plan coverage, obvious-issue scan (bugs, security smells, leftover, naming), and a maintainability pass with a clean-code check (structure, coupling, naming, complexity, duplication, functions, conditionals, comments, code smells), writes findings to a color-coded report, and returns a verdict. Per the state's **Risk tier**, the review skill also dispatches a focused reviewer on high (not waived) tiers after the main reviewer clears green/blue — same host-specific model source (revalidated before dispatch), same R5 verdict contract, combined category brief, report to `review-report-focused.md`. Verdict and handling per the review skill's R5 verdict contract — green/blue advance to step 8; yellow surfaces the fix-now/note-in-PR choice; red rewinds to step 5.

This is the gate that makes the PR worth a human's review — it does not replace human review at the PR. The orchestrator acts on the reviewer's verdict; it does not re-do the review inline.

## Step 8 — Doc-fix (pre-PR)
**Gate:** `review` → set `doc-fix`. Invoke `dev-flow:doc-fix` to scan for doc drift caused by *this* run — this plugin's docs and the target repo's docs — guided (edits shown before applying), committed as `docs:` so they ride in the PR. If the target repo has no `docs/agents/` tree at all, doc-fix generates one via `dev-flow:document-structure` (skip if the user declines). It returns a verdict:
- **No drift** → no-op pass; advance to step 9.
- **Drift found** → show the proposed edits; on confirmation, apply and commit as `docs:`; advance to step 9.
- **Drift reveals a deeper code issue** → STOP; don't open a PR with known-bad docs (mirrors review's red); red-loop rewind per *The hard gate*.

## Step 9 — Open or update PR
**Gate:** require incoming `doc-fix`. After verifying that entry context, set `pr-review` and update the state file, index row, **Updated**, and **Status since** together; pass the verified `pr-review` context to `dev-flow:open-pr`. Invoke it, then run Step 10 automatically. The skill never merges.

For a new PR, `dev-flow:open-pr` keeps its guided title/body confirmation, then opens the PR targeting the state file's Target branch, links the existing issue, syncs the issue body, and records the PR identity. For a repair loop with an existing recorded PR, update that same PR and preserve its issue identity; do not create another issue or PR. Keep the existing guided checkpoint before publishing an update. A push/update requires authorization in the target repository; if it is not authorized, keep the local fix and return to `pr-review` pending for the user's push.

## Step 10 — PR check and manual merge
**Gate:** require `pr-review`; keep that status until the remote outcome is known. Read the repository and PR number/URL from References; missing or unreadable values leave the check `pending`. First use read-only `gh pr view` to read the PR state. If it is remotely confirmed `MERGED`, immediately record `merged` and continue to step 11 without readiness checks or old evidence. If it is `CLOSED` but not merged, record `pending`, keep `pr-review`, and ask the user to handle the closed PR. If state cannot be read, stay `pending`. Only an `OPEN` PR proceeds to readiness checks. Explicitly delegate the `pr-review` validation subflow to `dev-flow:review` (the only post-PR invocation that may bypass its ordinary step-7 `test` status gate). Confirm the repository, PR head SHA, base ref and base SHA against the recorded PR, the state file's Target branch, and actual PR diff/scope. Use read-only `gh pr view`, `gh pr checks`, and, when needed, GitHub API queries for PR state, mergeability, review decision, unresolved blocking review threads, required checks, and branch protection/rulesets. The agent must verify the current CLI/API schema for every queried field; errors, missing permissions, unknown mergeability, unknown rules, or unreadable results are `pending`, never evidence of absence or success. Ordinary comments are not authorization to change scope.

Before any delegated test or review work, verify the local repository, `HEAD`, base ref, and base SHA equal the captured PR tuple, and inspect the worktree for relevant changes. If the local checkout is behind/ahead of the PR, the base differs, or relevant changes are dirty, do not dispatch verification against the wrong version; keep the check `pending` until an authorized push/update makes the checkout match. A local push prohibition applies only when the target repository's authorization forbids pushing; otherwise use Step 9's authorized update flow. Never overwrite user work. Validate saved Test and Review evidence against the exact PR repository/head/base tuple. If evidence is missing, stale, or does not cover the PR diff, request the required step-6 test and step-7 review work through the validation subflow; preserve the Tester and Reviewer lanes, fresh-gate and report rules, and return to Step 10 afterward. If a doc-fix commit changed HEAD, rerun the test gate and perform the applicable incremental review against that commit before returning to Step 10. Successful supplementation returns directly to Step 10; only actual findings rewind to execute. Do not rerun doc-fix just because evidence was supplemented. Evidence from an unpushed local head remains recorded but cannot pass the remote PR. Never attribute a dirty working tree to a commit.

For an actionable finding within the existing task authorization, rewind to `execute` by updating Goal status, the index row, **Updated**, and **Status since** together. Preserve the saved Roles block and existing Tasks; append the concrete repair work to Tasks. Ask before expanding the task's authorized scope. Then run steps 5–9 in order (test → review → doc-fix → update the same PR) and return here. If the same PR version and same reason recur without a new change or new verification result, stop retrying, record the reason in `## PR check`, keep `pr-review`, and ask for the input needed to proceed.

If required checks are pending, re-query at intervals no longer than 60 seconds, up to 300 seconds total in this invocation, and report progress. Resume starts a new 300-second budget. Record `needs-fix` for a failed required check, merge conflict, or blocking review decision; record `pending` for checks still running, timeout, approval wait, unknown mergeability/rules, or unreadable/permission-denied results. Only an all-clear result with complete matching evidence may be `passed`. Diagnose failures; timeout remains `pending`. Only explicitly confirmed absence of CI, together with complete matching local evidence and no applicable required checks, may pass with reason `CI not configured`. A configured check with no result, approval-gated check, unknown protection/ruleset, or missing required check is not absence and cannot pass. Before recording `passed`, reread PR head, base ref, and base SHA; any change invalidates this round's pass. Archive each report under `docs/features/.pr-review/<feat-name>/pr-check-report.md`; before rerunning, rename the existing report to the next free `pr-check-report-<n>.md`. Record repository, PR number/URL, head SHA, base ref/SHA, checked time, result (`passed`, `pending`, or `needs-fix`), reason, and report path in `## PR check`. This result is not a Goal status.

Only after a passed check, tell the user the open PR is ready for their manual review and merge. Never merge. The initial remote-state read handles already merged and closed-unmerged PRs before any readiness check. At the end of an open-PR check, reread remote state; only a confirmed `MERGED` result advances to `merged`. If state remains open, wait for manual merge at `pr-review`. If it becomes closed-unmerged, keep `pr-review` with `pending` and require user handling. If remote state or mergeability cannot be read, do not accept a user statement alone as merge confirmation. `merged` is the intermediate — a crash here lands back on `merged` and re-runs step 11 (close-out).

Issue closing follows the user's intended closure path. If the user requires closure through PR merge, preserve `Closes #N`; never directly close the issue as a substitute. Preserve the keyword even though a Target branch that is not the default branch means the merge may not auto-close the issue; after remote merge, say so and give the user the manual action if restrictions permit.

## Step 11 — Close-out
**Gate:** `merged` → set `done`. The work is shipped and the doc-fix already happened in step 8; step 11 is **close-out only** — no doc edits here **except the roadmap refresh** (below).

Look at:
- **Persisted agent memory** (if the harness keeps it) — only durable, cross-session facts (a user preference confirmed this run, a project constraint discovered). Skip ephemeral task state — that's the state file's job.

Rules:
- **Roadmap refresh** — if the state file's References carry an Overview path and that file exists, refresh the overview spec with what the completed run changed and taught: mark the run's entry done, record learnings, adjust later-run entries if direction shifted. Then print the exact next-run bootstrap command: `/new-feature <overview-spec-path> <next-run-name>`. The user starts the next run manually — no cross-run automation. No Overview path, or it doesn't exist → skip silently and say so.
- **Show the user any proposed memory update before applying** — close-out is guided, not fire-and-forget.
- **No memory update needed** → say so plainly and mark the run `done`. Don't invent edits to justify the step.
- **Ask before deleting the branch** — after the merge, offer to clean up: check out the state file's Target branch first (you can't delete the branch you're on), then `git branch -d <branch>` locally (safe post-merge) and `git push origin --delete <branch>` for the remote. Only with the user's yes; a declined offer is a normal outcome, not a failure.
- **Read close-out restrictions** — before any branch cleanup, remote issue action, or other remote modification, read the applicable user and repository restrictions. They bind scripts, CLIs, and APIs too. If remote branch deletion is prohibited, finish only the authorized close-out, hand off the exact command and context, and record it as pending for the user; don't ask again for the same prohibited operation or claim it happened.
- **Record the task outcome** — before marking the run done, append the `## Task outcome` section to the state file per `references/task-outcomes.md` (format, collection, honesty rules). The section is measurement-only: no workflow gate reads it and it cannot affect resume logic.
- **Never commit `docs/features/`** (preflight + commit guard keep it ignored).

When done, the run is `done` — fully closed. The state file and index row stay as history.

## Notes
- No configured target branch → delegate to `dev-flow:create-github-issue`’s **Branches** missing-target procedure: read runtime restrictions before offering any creation or publication action, hand off prohibited operations without re-asking, and ask only among permitted branch choices. Don’t silently pick.
- Keep the user in the loop at each checkpoint; this is guided, not fire-and-forget.
- The state files are the source of truth for resuming — keep them honest. A stale state file is worse than none.
- The hard gate is the backbone. If you're doing step N's work while the state file is at a different status, stop and fix the state file first.
