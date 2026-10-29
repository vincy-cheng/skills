---
name: plan
description: Use when turning an approved spec or settled requirements into an implementation plan — bite-sized ordered tasks with files, TDD shape, and a flow chart. Runs standalone in any repo, or as the engine of dev-flow step 3 (invoked by the new-feature command).
---

# Planning

Turn an approved design into a complete implementation plan — bite-sized tasks a fresh implementer could execute one by one with TDD.

**Core principle:** The plan is complete only when every downstream consumer can run from it alone. In a dev-flow run those consumers are steps 4–11; standalone, they're whoever executes next. **No implementation action** — the plan is written, presented, and approved; building starts after approval. The terminal state is the approved plan **carrying its `## Plan review pass` section** — see below; a plan without one is not approvable.

**Precondition:** an approved spec or settled requirements. If neither exists, do not write the plan — say so and ask for the design to be settled first (in a dev-flow run, that means back to step 1 / `dev-flow:brainstorm`; never invent requirements to fill the gap).

## The contract

A plan serves these consumers; every one must be satisfiable from the plan document alone:

| Consumer | What it needs from the plan |
|----------|------------------------------|
| Issue draft | Overview text, scope, acceptance-criteria fragments per task |
| Task execution (TDD) | Ordered bite-sized tasks; per-task Files block; test-first shape via `dev-flow:tdd` |
| State file | The task list, copyable verbatim as `- [ ]` items |
| Coverage checks (test/review) | Plan tasks to check spec/plan coverage against |
| The reader | The flow chart — task order plus per-task blast radius at a glance |

If a consumer's need is unmet, the plan is incomplete — fix the plan, not the consumer.

## Mandatory plan sections

Write the plan to:

```
docs/features/plans/YYYY-MM-DD-<feat-name>.md
```

(dev-flow conventions: always under `docs/features/` — never `docs/superpowers/`; the plan is never committed.)

In this order:

1. **Overview** — one paragraph; what changes end-to-end; links the spec (a `docs/features/specs/YYYY-MM-DD-<feat-name>-design.md` path — never linked from committed files).
2. **Global Constraints** — rules every task inherits: conventions, never-commit rules, commit style, suite-green requirement.
3. **Flow Chart** — mandatory (see below).
4. **File Structure** — the files created/modified, as a tree keyed to tasks.
5. **Tasks** — the task list (rules below).

## Flow Chart

The plan must include a `## Flow Chart` section, right after Global Constraints and before File Structure. A Mermaid `flowchart` showing what to do and what changes:

- Each task is a node labeled `Task N: <name>`, connected in execution order with `-->`.
- Draw a dependency edge (`-.->` labeled `blocks`) where a later task depends on an earlier task's exact output — surfaces the critical path.
- State each task's files **inside its node label** — e.g. `T1["Task 1: name<br/>changes: file_a, file_b"]`. A bare `Task N changes:` line outside a node label is invalid Mermaid and breaks the chart — never omit the "what changes".

Keep it honest: every task node matches a `### Task N` heading; every file under a node appears in that task's **Files:** block. Update the chart in the same edit if tasks change — a stale flow chart is worse than none.

## Task rules

- **Bite-sized and ordered** — each task is one concern, independently verifiable, executable in order without jumping ahead.
- **Test-first shape** — each task states its test (what failing check proves it) and its verification command; follow `dev-flow:tdd` for the red-green loop. For docs-only work, the test is the repo's consistency suite or an explicit grep check — state it.
- **Files block** — every task lists the files it creates/modifies.
- **Risk line** — every task carries a `Risk:` line beside its `**Files:**` block: `Risk: low` or `Risk: high — <category>`. Low must be written explicitly — **unmarked ≠ low** (fail-closed; a task with no Risk line is a defect, not a default-low). High names one of four categories — the bars, not a list: **executable-code** (newly introduced privileged/triggered execution paths, not file-type presence), **destructive-operations** (commands that delete or force-rewrite), **auth-permissions** (auth spine, middleware, permission checks, session handling), **blast-radius** (diff breadth out of proportion to the task's stated scope). The human sees the full risk surface at plan approval. The `Risk:` line rides in the plan's task body only — the state file's Tasks copy stays clean `- [ ]` main text; tier info lands in the state's Risk tier field via the step-7 recheck, not in the copied lines (the verbatim-copyable contract is preserved).
- **Verbatim-copyable** — the task list is what the state file's Tasks block copies; write them as clean `- [ ]` lines.
- **Issue material** — each task carries an acceptance fragment the issue can lift directly.
- **Verification per task** — name the command that proves the task done (the repo's suite, a grep, a lint run).

## Prose quality (plan text)

Plans are read by humans at every checkpoint. Write them under the brainstorm skill's prose-quality rules (one term per concept, frozen modals — shall, must, will, may never swap force — sentences ≲ 20 words, no vague quantifiers, active voice); those rules live once in `skills/brainstorm/SKILL.md` *Spec output*. Plan-specific addition:

- Task lines stay verbatim-copyable — style rewrites never touch them, nor the `Risk:` lines.

## Self-review

Before presenting the plan, check it with fresh eyes and fix inline: every task has a `Risk:` line (a task missing one is a fail-closed defect, not a default-low — fix it before the plan is presented); no placeholders ("TBD", "TODO"); the Flow Chart's nodes match the `### Task N` headings and their files match the `**Files:**` blocks; the task list is clean `- [ ]` lines, copyable verbatim.

## Plan review pass

After generation and self-review, before presenting the plan for approval, dispatch a fresh plan reviewer — the plan skill is the plan's author, so it must not judge the plan alone (the same fresh-eyes pattern as the brainstorm viability red-team and the test/review gates).

**Dispatch.** Fresh subagent, read-only critique. Lane: config `roles.reviewer` from `.dev-flow/config.json`; unset → `session`; malformed or unavailable lane → BLOCKED stop-and-ask per the routing error contract, never a silent downgrade. Standalone mode has no config context to trust — ask the lane directly (same shape as the review/test skills' standalone ask).

**Checklist — judgment only.** The reviewer checks: does the task list cover the whole spec (nothing quietly skipped); is the order sane (no task reading an earlier task's output that lands later); missing or phantom work (spec asks with no task, tasks doing work outside the spec). It does **not** re-run the contract-shaped checks above — `## Self-review` already owns Risk-line, Flow-chart, and verbatim-copyable presence, and grep-able structure checks gain nothing from a subagent dispatch.

**Verdict — binary.** `pass` or `needs-rework`; no middle states. A plan is not shippable-with-notes, so "yellow" has no meaning here. On `needs-rework`, revise the plan per the findings and re-dispatch — maximum 2 rework rounds (3 dispatches total). Still `needs-rework` after round 2 → stop and present the findings to the user; that stop is the real judgment signal.

**Tiering + waiver.** A trivial plan (a single mechanical task, or a docs-only word change) may run a one-line self-check instead of the dispatch — but the choice is shown to the user first, and the user may demand the full pass. The pass is never silently skipped.

**Recording.** The pass writes a `## Plan review pass` section into the plan document: the verdict, the findings with their handling, rounds used, and the model used when the lane was configured (adversarial review on an external model must not be silent). A plan without this section is **not approvable** — the section is the structural trace that makes a silently-skipped pass visible.

## Standalone mode

In any repo, without dev-flow: same sections, same contract — the consumers are whoever executes next (a human, an agent session, a team). Save the plan wherever the repo's convention puts planning docs; if none, use `docs/plans/`.

## dev-flow integration

**In-flow mode:** invoked by `dev-flow:new-feature` step 3.

- **No handoff.** This skill never advances, skips, or reorders dev-flow steps, and never invokes other skills. Its terminal state is the approved plan; control returns to the orchestrator; step order is governed solely by the hard gate in `skills/new-feature/SKILL.md`.
- Plans are never committed. Artifacts stay under `docs/features/` — never `.superpowers/`.