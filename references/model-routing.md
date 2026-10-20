# Model routing — role-level lanes for dev-flow subagent dispatch

Single source of truth for dev-flow's model routing: lane semantics, config schema, availability checks, the thin-driver flow, the sandbox map, commit ownership, and the error contract. Every dispatching skill (`execute-tasks`, `test`, `review`, and the brainstorm viability red-team) points here and never re-derives lane semantics from its own text.

Roles: **implementer** (execute-tasks step 5, one per task), **tester** (test step 6), **reviewer** (review step 7 — main and focused reviewer share the pick), **red-team** (brainstorm viability pass, config-only).

## Lanes

A lane value pins where a role's work executes. Four values:

| Value | Meaning | Dispatch shape |
|-------|---------|----------------|
| `inline` | implementer only — the task runs in the current session, no subagent. TDD still applies. | no dispatch |
| `session` | claude lane on the session's default model — today's default shape. | Agent tool, no model pin |
| `claude:<name>` | claude lane on a named model — `<name>` is any name the session's model picker shows (`sonnet`-family names, gateway names like `github/gpt-5.4`, `github/claude-haiku-4.5-high`). | Agent tool via the resolution rule |
| `cli:<tool>/<model>` | an external CLI's model. v1 tool: `codex` (e.g. `cli:codex/gpt-5.3-codex`). | thin-driver flow |

`session` is the claude lane's unpinned shorthand, not a separate lane. Tester/reviewer are separate picks (pre-filled identically at the combined ask, but independently overridable from v2 on — v1 keeps them one answer unless the user overrides).

## Resolution rule (`claude:<name>`)

The dispatching skill resolves `<name>` against the session's model list, in this order:

1. **Model-param family name** (`sonnet`, `opus`, `haiku`, `fable` families) → dispatch with the Agent tool's `model` param.
2. **Gateway/agent-type name** (anything else the picker shows, e.g. OmniRoute names) → dispatch via `subagent_type`. The agent-type list is session-scoped: confirm the type exists before dispatch. A named type that 404s → fall back to `general-purpose` **and report the fallback to the user** — never a silent lane switch.
3. **Unresolvable** (the name matches nothing in the session's list) → fail-closed: BLOCKED stop-and-ask per `## Error contract`.

## Config schema

Optional `roles` key in `.dev-flow/config.json` (per-repo, gitignored, per-machine — model availability lives on the machine, not the repo):

```json
{
  "dev_branch": "dev",
  "roles": {
    "implementer": "inline",
    "tester": "claude:github/gpt-5.4",
    "reviewer": "cli:codex/gpt-5.3-codex",
    "red-team": "session"
  }
}
```

- Each key maps a role to a lane value from `## Lanes`.
- Omitted role → that role behaves exactly as before (implementer: the current default flow; tester/reviewer: session; red-team: no model pin).
- The whole `roles` key omitted → zero-change default.
- A **malformed** value (unknown role, unknown lane syntax, empty) is NOT unset — it is a BLOCKED stop-and-ask per `## Error contract`.
- Config is the long-term default; per-run picks live in the state file's Roles block. No per-task overrides in v1.

## Availability checks (dispatch-time, fail-closed)

Before dispatching on a lane, verify:

- **cli lane:** tool binary present (`command -v <tool>`), **and authenticated** (`codex login status` for codex — binary presence is not auth), Bash available.
- **claude lane:** when resolving via `subagent_type`, the type exists in this session's list; per `## Resolution rule` step 2.
- **Any lane:** Bash/tool dispatch possible at all in the current environment.

Any check failing → BLOCKED stop-and-ask. **Quota exhaustion mid-run** → BLOCKED with resume-later semantics (state stays put; a later resume re-attempts the lane). Never a silent downgrade to another lane.

## Thin-driver flow (cli lane)

The cli lane runs one role's work through an external CLI, driven by a cheap in-session Claude subagent:

1. The dispatching skill spawns one **driver** subagent (claude lane, cheap/standard — it composes and relays, it does not judge content).
2. The driver composes the role's brief + the role's **report contract** — copied **verbatim at runtime** from the skill's own contract section (never paraphrased or remembered) — into the run folder `docs/features/.routing/<feat>/`.
3. The driver runs the CLI via Bash, e.g.: `codex exec --model <model> --sandbox <s> -C <repo> <brief-path>` — sandbox from `## Sandbox map`.
4. The external model reads the brief, does the role's work, and **writes the role's existing report artifact to the role's existing path** (`.sdd/<feat>/task-N-report.md`, `.test/<feat>/test-report.md`, review report likewise) — the writer changes, never the path.
5. The driver reads the report and relays a **per-role payload**:
   - **implementer:** status + commits + one-line test summary — and the report itself must contain the RED-phase test output **verbatim** (test-first attribution survives the one-shot invocation). Missing/stale report file = hard failure → BLOCKED.
   - **tester:** green/red verdict + failure list.
   - **reviewer:** verdict + **full findings verbatim** — the R5 yellow choice (fix-now vs note-in-PR) must reach the user uncompressed.
   - Missing/stale report file for any role = hard failure → BLOCKED stop-and-ask.
6. **Commit ownership:** the external model is **prohibited from committing**. The driver scopes the working-tree diff and commits via the `dev-flow:commit` conventions (Conventional Commits, **no AI attribution**) — per-task commits keep their contract regardless of lane.

## Sandbox map

Fixed by role — lane semantics, not a user-tunable parameter. No per-role overrides.

| Role | codex sandbox | Why |
|------|--------------|-----|
| implementer | `workspace-write` | writes code + tests |
| tester | `workspace-write` | runs the suite, writes reports |
| reviewer | `read-only` | judgment only — never edits |
| red-team | `read-only` | design critique only |

**Known limitation (record, never work around silently):** `codex exec --sandbox workspace-write` **denies network access by default**. A tester on the cli lane in a repo whose suite needs dependency installs (`npm ci`, `pip install`) hits this: it is a **known BLOCKED with a resume hint** (fix the lane in config, or prepare dependencies first, then re-dispatch) — **never** a false "tests failed" gate signal.

## Error contract

All lanes, all roles:

- **Lane unavailable, malformed config entry, auth failure, missing Bash, missing/stale report, unresolvable `claude:<name>`** → **stop-and-ask**: report what failed and what was attempted, wait for the user's instruction. Malformed ≠ unset — a malformed entry is never treated as the default.
- **No silent downgrade anywhere.** Falling back to another lane or to the session default without asking is a contract violation, not resilience.
- **Quota exhaustion mid-run** → BLOCKED with resume-later semantics.
- **404 on a named agent type** (claude lane, resolution step 2) → `general-purpose` fallback **with a user-visible report** — the one sanctioned fallback, because the dispatch axis is preserved.

## Scope

v1 is Claude Code only — other hosts ignore the `roles` table. No scripts or hooks implement routing; the logic lives in skill text, and this doc is its single source.