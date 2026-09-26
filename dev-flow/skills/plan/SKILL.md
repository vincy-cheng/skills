---
name: plan
description: >-
  Use when turning an approved spec or settled requirements into an
  implementation plan — bite-sized ordered tasks with files, TDD shape, and a
  flow chart. Runs standalone in any repo, or as the engine of dev-flow step 3
  (invoked by the new-feature command).
---

# Planning

Turn an approved design into a complete implementation plan — bite-sized tasks a fresh implementer could execute one by one with TDD.

**Core principle:** The plan is complete only when every downstream consumer can run from it alone. In a dev-flow run those consumers are steps 4–11; standalone, they're whoever executes next. **No implementation action** — the plan is written, presented, and approved; building starts after approval.

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
- List the files each task touches under its node: `Task N changes: file_a, file_b` — never omit the "what changes".

Keep it honest: every task node matches a `### Task N` heading; every file under a node appears in that task's **Files:** block. Update the chart in the same edit if tasks change — a stale flow chart is worse than none.

## Task rules

- **Bite-sized and ordered** — each task is one concern, independently verifiable, executable in order without jumping ahead.
- **Test-first shape** — each task states its test (what failing check proves it) and its verification command; follow `dev-flow:tdd` for the red-green loop. For docs-only work, the test is the repo's consistency suite or an explicit grep check — state it.
- **Files block** — every task lists the files it creates/modifies.
- **Verbatim-copyable** — the task list is what the state file's Tasks block copies; write them as clean `- [ ]` lines.
- **Issue material** — each task carries an acceptance fragment the issue can lift directly.
- **Verification per task** — name the command that proves the task done (the repo's suite, a grep, a lint run).

## Standalone mode

In any repo, without dev-flow: same sections, same contract — the consumers are whoever executes next (a human, an agent session, a team). Save the plan wherever the repo's convention puts planning docs; if none, use `docs/plans/`.

## dev-flow integration

**In-flow mode:** invoked by `dev-flow:new-feature` step 3.

- **No handoff.** This skill never advances, skips, or reorders dev-flow steps, and never invokes other skills. Its terminal state is the approved plan; control returns to the orchestrator; step order is governed solely by the hard gate in `commands/new-feature.md`.
- Plans are never committed. Artifacts stay under `docs/features/` — never `.superpowers/`.