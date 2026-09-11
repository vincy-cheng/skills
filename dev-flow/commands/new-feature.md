---
description: Start a new feature or fix through the full workflow — brainstorm → spec → plan → create issue → execute (TDD) → review → doc-fix → PR → manual merge → close-out. Pass the idea as arguments; pass nothing or "resume" to continue prior work. Maintains gitignored state files so work can resume. Requires the superpowers plugin (brainstorming, writing-plans, test-driven-development).
---

# New feature or fix — full workflow

Drive this work through all steps, in order. Do not skip steps "because it's simple" — the user wants the full pipeline every time. Works for features **and** fixes. Arguments: $ARGUMENTS.

Steps: 1 brainstorm → 2 spec → 3 plan → 4 create issue → 5 execute (TDD) → 5.5 review → 5.6 doc-fix → 6 PR → 7 merge (manual) → 8 close-out.

Run each step before the next. Pause at the natural checkpoints (after spec, after plan, after issue draft, before PR). State which step you're on as you begin it.

**Resume:** if $ARGUMENTS is empty, a feat-name, or the word "resume", go to **Resume** below and discover/continue existing work before starting anything fresh.

## Peer dependency — superpowers

Invokes `superpowers:brainstorming`, `superpowers:writing-plans`, and `superpowers:test-driven-development` as sub-steps; runs its own `dev-flow:execute-tasks`, `dev-flow:review`, `dev-flow:create-github-issue`, and `dev-flow:commit` skills. Superpowers **must** be installed for the three `superpowers:*` skills.

**Missing-superpowers check — run at the start of every step that invokes a `superpowers:*` skill (steps 1, 3, 5):** if the skill is unavailable, **stop before doing any other work** and tell the user, in plain language:

> dev-flow needs the `superpowers` plugin for this step, but it isn't installed. Install it and retry:
> - `/plugin install superpowers` (from the official marketplace), or
> - `claude plugin install https://github.com/obra/superpowers.git`
>
> Then run `/new-feature` again — your state file is intact and you'll resume right here.

Don't dump the rest of the step or attempt a fallback. The run pauses cleanly; once superpowers is present, resume picks up from the state file's **Goal status**.

**Superpowers defaults lose to dev-flow.** Superpowers' SessionStart injection urges invoking its skills before any response, and its skills carry their own defaults (`docs/superpowers/` save paths, design-doc commits, "Execution Handoff"). Inside this workflow those defaults **do not apply**:

- Before writing any file for this run, verify the target is under `docs/features/` — never `docs/superpowers/`. If a superpowers sub-skill already wrote there, move the file (step 2 does this).
- Never commit specs, plans, or state files (see *Commit guard*). Superpowers' "commit the design document" instruction does not override this.
- A sub-skill's handoff never advances, skips, or reorders steps — see *The hard gate*.

## The hard gate

Steps 1 and 3 invoke superpowers skills with their **own** handoff instructions (brainstorming → writing-plans; writing-plans → "Execution Handoff"). Left unchecked, those handoffs **will** skip or reorder this workflow. The gate prevents it **structurally**: the state file's **Goal status** is the only thing that advances a step.

**Gate check — run at the start of every step:**
1. Read `docs/features/.feature-states/<feat-name>.state.md`.
2. Compare **Goal status** to the status this step requires (table below).
3. Match → proceed. No match → STOP; tell the user the current status and the step it maps to, and resume from there. Do **not** do the current step's work.
4. Set **Goal status** to this step's status *before* the work, so a crash/resume lands back on this step. **A status change is two writes, done together in one breath: the state file's Goal status and the index row** (see *Index file*) — add or update the feat's row with the new status + timestamp, re-sort newest-first. One without the other is an incomplete step. Step 1 adds the row; later steps update it.

Lifecycle: `brainstorm` → `spec` → `planning` → `issue` → `execute` → `review` → `doc-fix` → `pr-review` → `merged` → `done`. A step runs only on the immediately preceding status and advances only to the next when done. `doc-fix` is the pre-PR doc-fix (step 5.6); `merged` means "shipped, close-out pending" — the crash-resume safety net between "user confirmed merge" and "close-out complete"; `done` means fully closed.

| Step | Requires incoming | Sets |
|------|------------------|------|
| 1 brainstorm | _(fresh / no state file)_ | `brainstorm` |
| 2 spec | `brainstorm` | `spec` |
| 3 plan | `spec` | `planning` |
| 4 issue | `planning` | `issue` |
| 5 execute | `issue` | `execute` |
| 5.5 review | `execute` | `review` |
| 5.6 doc-fix | `review` | `doc-fix` |
| 6 PR | `doc-fix` | `pr-review` |
| 7 merge | `pr-review` | `merged` |
| 8 close-out | `merged` | `done` |

**Sub-skill handoffs — ignore them; return to the next dev-flow step:**
- `brainstorming` finishes → **step 2 (spec)**, not its handoff to writing-plans.
- `writing-plans` finishes → **step 4 (create issue)**, not its Execution Handoff. The issue must exist first (the branch is named `feature/<n>-<name>` or `fix/<n>-<name>`).
- Gate check fails → STOP and resume from the status the state file names. Don't "helpfully" follow the sub-skill.

The state file is the single source of truth for "what step am I on." On any doubt or ambiguity: run the gate check.

## State files

Two gitignored files under `docs/features/.feature-states/` (the whole `docs/features/` folder is gitignored — never commit; add to `.gitignore` on first use if missing):

- **Per-feature state file** — `<feat-name>.state.md`. `<feat-name>` is kebab-case, matching spec/plan filenames and the branch name. Created in step 1; updated on every status change. The source of truth.
- **Index file** — `state.md`. Mirrors all runs so you can see the current/last one at a glance. A convenience, not a second source of truth; if it disagrees with the state files, rebuild it from them.

### Per-feature state file

```markdown
# <feat-name> — dev-flow state

- **Created:** YYYY-MM-DD HH:MM±HH:MM
- **Updated:** YYYY-MM-DD HH:MM±HH:MM
- **Base branch:** <branch>
- **Target branch:** <branch>
- **Goal status:** <status>
- **Kind:** feature | fix
- **Last verification:** YYYY-MM-DD HH:MM±HH:MM — <test cmd> <passed|failed>, <lint cmd> <clean|warnings>

## Tasks
- [ ] <task description>

## References
- Spec: docs/features/specs/YYYY-MM-DD-<feat-name>-design.md
- Plan: <path or _(pending)_>
- Issue: <#NN or _(pending)_>
- PR: <#NN or _(pending)_>
```

Field rules:
- **Created** — set once in step 1, never changes. Carries local time + UTC offset (e.g. `2026-09-10 14:45+08:00`), so a reader never has to guess the zone.
- **Updated** — current timestamp on *every* write. Local time + UTC offset (e.g. `2026-09-10 14:45+08:00`).
- **Goal status** — the gate's input; set to the current step *before* the work.
- **Kind** — `feature` or `fix`, set in step 1 from intent. Drives the branch prefix and issue framing. Ambiguous → ask; default `feature`.
- **Last verification** — most recent test + lint result during execute (the repo's commands). The resume signal: "was it green when I stopped?" `_(not run yet)_` until first run.
- **Tasks** — mirrors the plan's task list as `- [ ]` / `- [x]`; flip on every status change. Live progress; the plan doc is static design. Annotate a task `— ⚠ test failing: <reason>` only when its test exists and is currently red; clear when green. Don't annotate passing/pending tasks — a `[x]` already means its test passed.
- **References** — spec (step 2), plan (step 3), issue (step 4), PR (step 6). Review (step 5.5) adds no reference. Replace `_(pending)_` with the real value when it exists.

### Index file

```markdown
# dev-flow runs

| Feat-name | Kind | Status | Issue | Updated | Branch |
|-----------|------|--------|-------|---------|--------|
| <feat-name> | feature | execute | — | YYYY-MM-DD HH:MM±HH:MM | feature/42-x |
| <feat-name> | fix | done | #17 | YYYY-MM-DD HH:MM±HH:MM | fix/17-y |
```

One row per feat; newest **Updated** first (re-sort on every write). The top non-`done` row is the current run; `done` rows stay as history — don't delete them. The **Issue** column is `—` until step 4 creates the issue, then `#NN` for the row's life (set in step 4's two-writes-in-one-breath, never changes after). Maintained alongside the per-feature state file on every status change (and during execute on every task/test, via `execute-tasks`). Stale-row cleanup: if a feat's state file is gone, drop its row. Never invent rows — the state files are the source of truth; the index only mirrors them.

## Resume

You may not remember the feat-name you were on. The index file records it — open `docs/features/.feature-states/state.md` and the current/last run is the top non-`done` row.

- **No feat-name in $ARGUMENTS (or "resume"):** read the index; present the active rows numbered; resume the topmost unless the user picks another. Index missing → fall back to scanning `docs/features/.feature-states/*.state.md`, sort by **Updated**, rebuild the index. Zero state files → start fresh from step 1.
- **Feat-name given in $ARGUMENTS:** use it directly. State file missing for it → tell the user; don't silently start fresh.

Then **run the gate check**: read that feat's state file, jump to the step matching **Goal status**, reload referenced spec/plan/issue, continue. Don't restart from brainstorm. `review` → re-run `dev-flow:review`. `doc-fix` → re-run step 5.6 (idempotent: re-scan for drift, re-apply). `pr-review` → open the PR and stop at the manual merge gate (step 7). `merged` → run step 8 (close-out).

Only `done` is "finished" — `merged` still has close-out pending. Treat `done` rows as history; resume any non-`done` row.

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

Three local-only artifacts under `docs/features/` (spec, plan, state) must never be committed or pushed.

- After a step writes a file there, spot-check `git check-ignore docs/features/specs/<file>.md` returns the path before moving on.
- In step 5, stage explicitly (`git add <specific files>`), never `git add -A` / `git add .` — guards against leaking if gitignore drifts.
- Before pushing in step 6, confirm `git status --porcelain docs/features/` is empty. If not, stop and fix.

## Step 1 — Brainstorm
**Gate:** fresh start → set `brainstorm`. Create the state file (default base `dev`, target `dev` — target is the PR destination; for `main`-only repos, both are the default branch) and add the index row. Set **Kind** from intent (ask if ambiguous). Invoke `superpowers:brainstorming` to explore intent, requirements, design. Don't write code. Brainstorming will hand off to `writing-plans` — **don't follow it**; advance to step 2.

**Idea-folder ingestion — run when arguments reference an idea folder.** If `$ARGUMENTS` contains a path to an existing idea folder (`ideas/[<project>/]<slug>/`, from `/new-idea`) or names one that exists, read its docs **before** invoking brainstorming and treat them as the established brief — don't re-derive what's settled (folder has five required docs; a sixth `cost.md` may be present if the user opted into cost research — read it if present, proceed without it if not):

- `README.md` → problem/goal — the starting brief, carried forward.
- `design.md` → proposed approach — the starting point for design decisions; settled choices aren't re-litigated.
- `cost.md` → constraints — a decided tier/price is a spec constraint, not an open question.
- `plan.md` → milestone shape — feeds step 3's plan; still refined there, not copied.
- `research.md`, `tl-dr.md` → background; load on demand.

Record the folder path in the state file's References. Brainstorming still runs — it validates and refines the draft against the current codebase rather than exploring from zero. If the path doesn't exist, say so and proceed as a normal fresh start.

## Step 2 — Spec (local only)
**Gate:** `brainstorm` → set `spec`. Carry brainstorming's output forward; don't re-derive. **If `superpowers:brainstorming` already wrote a design doc under `docs/superpowers/specs/`, move it to `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md`** (brainstorming defaults to `docs/superpowers/specs/`; dev-flow keeps everything under `docs/features/`). If not yet written, write it there directly. Local reference, not published. Add the path to References; show the user. Verify it's gitignored before moving on.

## Step 3 — Plan
**Gate:** `spec` → set `planning`. **Invoke `superpowers:writing-plans` and follow it** — the plan is generated through that skill, not hand-authored. **Tell writing-plans to save the plan to `docs/features/plans/YYYY-MM-DD-<feat-name>.md`** (it defaults to `docs/superpowers/plans/`; dev-flow overrides that). Bite-sized tasks, TDD, frequent commits; reference the spec. Copy the task list into the state file's Tasks; add the plan path to References. Verify it's gitignored. `writing-plans` will offer an Execution Handoff — **don't take it**; advance to step 4.

### Flow chart is mandatory in every plan

The plan **must** include a `## Flow Chart` section, placed right after `## Global Constraints` and before `## File Structure` / the first task. It shows what to do and what changes — task flow plus per-task blast radius — so a reader grasps the whole change at a glance.

Use a Mermaid `flowchart` (renders in VS Code and GitHub). For every task: **what it does** (task name) and **what it changes** (files, keyed to File Structure).

- Each task is a node labeled `Task N: <name>`.
- Connect in execution order with `-->`. Draw a dependency edge where one task blocks another (a later task imports a symbol an earlier task defines) — surfaces the critical path.
- List the files each task touches under its node, e.g. `Task N changes: file_a.dart, file_b.dart`. Never omit the "what changes".
- Add a second diagram for data/control flow (e.g. UI → service → DAO → DB) when the work spans layers. One task-flow chart is the minimum.

Example (adapt, don't copy):
```mermaid
flowchart TD
    T1["Task 1: Rename TWD→NTD<br/>changes: supported_currencies.dart"] --> T2
    T2["Task 2: Migration v12<br/>changes: migration_v12.dart, database.dart"] --> T3
    T3["Task 3: Read-side normalization<br/>changes: currency_provider.dart"]
    T2 -.blocks.-> T5["Task 5: Price NTD column<br/>changes: csv_import_service.dart"]
```

Keep it honest: every task node matches a `### Task N` heading, every file under a node appears in that task's `**Files:**` block. Update the chart in the same edit if a task is added/removed. A stale flow chart is worse than none.

## Step 4 — Create issue
**Gate:** `planning` → set `issue`. Invoke `dev-flow:create-github-issue` to turn the spec + plan into a tracked issue. Draft → user confirms → publish with `gh`; user picks labels. Offer a `feature/<n>-<name>` (or `fix/<n>-<name>`) branch off `dev`; update the state file's base branch and record the issue number in References.

## Step 5 — Execute tasks (TDD)
**Gate:** `issue` → set `execute`. Invoke `dev-flow:execute-tasks` to work the plan task by task with TDD (following `superpowers:test-driven-development`), committing per task via `dev-flow:commit` and updating the state file on every subtask start/complete and every test run. `execute-tasks` has two modes — **inline** (default, runs in this session) or **subagent** (fresh implementer per task, for isolation on larger work); it asks which. Either way, all artifacts stay under `docs/features/` (no `.superpowers/` workspace). When all tasks are `[x]` and the suite is green, advance to step 5.5.

## Step 5.5 — Review (gate before PR)
**Gate:** `execute` → set `review`. Invoke `dev-flow:review` to run a pre-PR self-review: full test + lint gate, spec coverage, plan coverage, obvious-issue scan. It returns **green / yellow / red**:
- **Green** → advance to step 6.
- **Yellow** (minor findings, non-blocking) → surface the list; let the user decide fix-now vs. note-in-PR. Still advance to step 6.
- **Red** (suite red, spec gap, real bug) → do **not** open the PR. Return to step 5 with the specific findings; fix and re-run review.

This is the gate that makes the PR worth a human's review — it does not replace human review at the PR.

## Step 5.6 — Doc-fix (pre-PR)
**Gate:** `review` → set `doc-fix`. The work is done and reviewed; before opening the PR, close the loop on docs the run itself may have invalidated. Find doc drift caused by *this* run — not a general audit.

Look at, in order of likelihood of drift:
1. **This plugin's docs** — `AGENTS.md`/`CLAUDE.md`, `README.md`, and any `dev-flow/skills/*/SKILL.md` touched by the work. Did the run change behavior a doc still describes the old way? Did a new convention emerge (e.g. a new state-file column this run added)?
2. **The target repo's docs** — `AGENTS.md`/`README`/arch docs in the repo the feature landed in. Did the change add a new module, command, or convention the docs should mention?

Rules:
- **Show the user the proposed doc edits before applying** — guided, not fire-and-forget (same rule the old post-merge distill used).
- **Commit doc updates as `docs:`-type commits**, riding in the PR alongside the code commits — a run's own drift should ship in the same PR, not surface after merge.
- **Never commit `docs/features/`** (spec, plan, state, index) — still gitignored.
- **No drift found** → quick no-op pass; say so plainly and advance to step 6. Don't invent edits.

If 5.6 finds drift it can't safely fix (e.g. reveals a deeper code issue), STOP and surface to the user — don't open a PR with known-bad docs (mirrors review's red). Return to step 5 if the drift reveals a real code issue. **Green** → advance to step 6.

## Step 6 — Open PR
**Gate:** `doc-fix` → set `pr-review`. Branch flow `main` → `dev` → `feature/<n>-<name>` (or `fix/...`); PR targets `dev`, never `main`. Push and open with `gh pr create`, body summarizing the issue link, spec, and plan. Reference the issue with a closing keyword (e.g. `Closes #N`) so merge auto-closes it; if the PR only partially resolves the issue, use a plain reference and say so. Record the PR number in References; surface the URL. Step 7 is manual — do not merge here.

**Auto-update the issue todo (no manual nudge):** by step 6 the work is done and reviewed, so the issue should reflect that automatically. After `gh pr create` returns the PR number:
- **Check the issue's acceptance-criteria boxes** that the work satisfied — flip `[ ]` → `[x]` for completed criteria. Fetch the issue body (`gh issue view <N> --json body -q .body`), check the boxes for criteria the PR completed, and write it back with `gh issue edit <N> --body ...`. Leave unchecked any criterion that isn't done. If the issue has no acceptance-criteria checklist, skip this part.
- **Add the PR link to the issue's References** — append `- PR: #NN` to the issue body's References block (create one if absent), again via `gh issue edit <N> --body ...`.
- Do both as part of step 6; don't ask the user to nudge them separately.

## Step 7 — Merge (manual)
**Gate:** `pr-review` → set `merged`. Do not merge. Tell the user the PR is ready for their manual review and merge. On their confirmation, record the merged state and advance to step 8 (close-out). `merged` is the intermediate — a crash here lands back on `merged` and re-runs step 8.

## Step 8 — Close-out
**Gate:** `merged` → set `done`. The work is shipped and the doc-fix already happened in step 5.6; step 8 is **close-out only** — no doc edits here.

Look at:
- **Persisted agent memory** (if the harness keeps it) — only durable, cross-session facts (a user preference confirmed this run, a project constraint discovered). Skip ephemeral task state — that's the state file's job.

Rules:
- **Show the user any proposed memory update before applying** — close-out is guided, not fire-and-forget.
- **No memory update needed** → say so plainly and mark the run `done`. Don't invent edits to justify the step.
- **Never commit `docs/features/`** — still gitignored.

When done, the run is `done` — fully closed. The state file and index row stay as history.

## Notes
- No `dev` branch → ask the user: create `dev` off the default branch (push it, then branch `feature/...`/`fix/...` off it), or run everything off the default branch. Don't silently pick.
- Keep the user in the loop at each checkpoint; this is guided, not fire-and-forget.
- The state files are the source of truth for resuming — keep them honest. A stale state file is worse than none.
- The hard gate is the backbone. If you're doing step N's work while the state file is at a different status, stop and fix the state file first.