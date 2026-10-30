# Model routing — role-level lanes for dev-flow subagent dispatch

Single source of truth for dev-flow's model routing: lane semantics, config schema, availability checks, the thin-driver flow, the sandbox map, commit ownership, and the error contract. Every dispatching skill (`execute-tasks`, `test`, `review`, the plan skill's plan review pass, and the brainstorm viability red-team) points here and never re-derives lane semantics from its own text.

Roles: **implementer** (execute-tasks step 5, one per task), **tester** (test step 6), **reviewer** (brainstorm red-team, plan review, and step-7 main and focused review). Select the host before interpreting routing settings: Codex reviewers follow **Codex reviewer model** below; Claude Code uses the lanes below. Implementer and tester routing is unchanged.

## Lanes

A lane value pins where a role's work executes. Four values:

| Value | Meaning | Dispatch shape |
|-------|---------|----------------|
| `inline` | implementer only — the task runs in the current session, no subagent. TDD still applies. | no dispatch |
| `session` | claude lane on the session's default model — today's default shape. | Agent tool, no model pin |
| `claude:<name>` | claude lane on a named model — `<name>` is any name the session's model picker shows (`sonnet`-family names, gateway names like `github/gpt-5.4`, `github/claude-haiku-4.5-high`). | Agent tool via the resolution rule |
| `cli:<tool>/<model>` | an external CLI's model. v1 tool: `codex` (e.g. `cli:codex/gpt-5.3-codex`). | thin-driver flow |

`session` is the claude lane's unpinned shorthand, not a separate lane. Tester/reviewer are separate picks — pre-filled identically at the combined ask, each line independently overridable by the user in that same turn.

## Resolution rule (`claude:<name>`)

The dispatching skill resolves `<name>` against the session's model list, in this order:

1. **Model-param family name** (`sonnet`, `opus`, `haiku`, `fable` families) → dispatch with the Agent tool's `model` param.
2. **Gateway/agent-type name** (anything else the picker shows, e.g. OmniRoute names) → dispatch via `subagent_type`. The agent-type list is session-scoped: confirm the type exists before dispatch. A named type that 404s → fall back to `general-purpose` **and report the fallback to the user** — never a silent lane switch.
3. **Unresolvable** (the name matches nothing in the session's list) → fail-closed: BLOCKED stop-and-ask per `## Error contract`.

## Config schema

Optional settings in `.dev-flow/config.json` (per-repo, gitignored, per-machine — model availability lives on the machine, not the repo):

```json
{
  "dev_branch": "dev",
  "roles": {
    "implementer": "inline",
    "tester": "claude:github/gpt-5.4",
    "reviewer": "cli:codex/gpt-5.3-codex"
  },
  "codex_reviewer_model": "<available-native-model>"
}
```

- `codex_reviewer_model` is an optional top-level string for Codex reviewers only. Replace the example placeholder with an option available in the current native subagent tool, or omit the key for the session default. See **Codex reviewer model** below.
- On Claude Code, each `roles` key maps a role to a lane value from `## Lanes`; the remaining lane rules in this section apply to that host.
- Omitted role → that role behaves exactly as before (implementer: the current default flow; tester: session; `reviewer`: session for all three judgment roles it feeds — step-7 review per the step-5 ask; brainstorm red-team and the plan review pass pinned to `session` directly).
- The whole `roles` key omitted → zero-change default.
- A **malformed** value (unknown role, unknown lane syntax, empty) is NOT unset — it is a BLOCKED stop-and-ask per `## Error contract`.
- Config is the long-term default; per-run picks live in the state file's Roles block. No per-task overrides in v1.

## Codex reviewer model

On Codex, ignore the `roles` table and state-file lane values when selecting reviewer models, even if those Claude lane values are malformed. On Claude Code, ignore `codex_reviewer_model` and keep the existing reviewer lane and external CLI behavior. The dev-flow Roles-presence gate still applies; this rule changes model selection, not the step-5 ask.

Before every fresh reviewer dispatch, including re-review, resolve this setting for brainstorm red-team, plan review, and step-7 main and focused review. Standalone Codex review and plan review use the same config read, without a Claude lane ask.

1. Read `.dev-flow/config.json` from the target repo. A missing file or absent key means the session default: omit the native `model` argument. An existing unreadable file, malformed JSON, or a non-object top level is invalid config, not an absent setting.
2. A present `codex_reviewer_model` must be a nonempty string. Reject empty or whitespace-only strings, null, boolean, number, array, and object values. Require an exact match against the current native subagent tool's model options or allowlist; do not trim, translate, or guess model aliases. Availability is session-specific, so do not hardcode a model list in the plugin.
3. Pass the validated string as the native subagent `model` parameter. Use fresh isolated context (`fork_turns: "none"` where exposed); read-only judgment and existing report contracts still apply. Follow the current tool's reasoning-effort rules independently; this setting adds no effort option.

**Failure:** invalid config, unavailable model, or a native tool that cannot validate or pin the requested model → **BLOCKED**, no reviewer dispatch. Show the key, failure reason, and correction/resume hint, then wait for the user. Never retry on another model, use a Claude lane or CLI driver, or silently substitute the session default. A rejected native dispatch follows the same stop-and-ask rule. Leave the workflow status in place for resume.

Record a configured model in the role's existing pass/report artifact. Re-resolve before the focused reviewer too; it shares this setting with the main reviewer, not a separate model source. This key never selects implementer or tester models.

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
| reviewer | `read-only` | judgment only — never edits (step-7 review, brainstorm red-team, plan review pass) |

**Known limitation (record, never work around silently):** `codex exec --sandbox workspace-write` **denies network access by default**. A tester on the cli lane in a repo whose suite needs dependency installs (`npm ci`, `pip install`) hits this: it is a **known BLOCKED with a resume hint** (fix the lane in config, or prepare dependencies first, then re-dispatch) — **never** a false "tests failed" gate signal.

## Before-starting procedures (tester / reviewer skills)

Shared by the `test` and `review` skills' `## Before starting` blocks — the gate outcomes (stop on a missing Roles block, BLOCKED on a malformed lane) stay in-skill; this section holds the two rarely-taken procedures those blocks reference.

- **Crash-recovery exception, explicitly scoped and verified:** if the block is missing and the user **confirms** the run crashed during step 5 before the combined ask completed its write — ask once, write the role's lane line to the state file, proceed, and note the recovery in the report. Never accept an unconditional "it crashed": if the user can't confirm the crash (e.g. they don't remember the step-5 ask at all), treat it as the skipped-ask case — stop and report. This is the only path that asks from the dispatching skill; every other missing-block shape stays a stop.
- **Pre-Roles upgrade mapping (read-only, never migrated on disk):** a state file predating the Roles block maps old fields onto the new lines — old `Implementer mode: inline` → Implementer `inline`; old `subagent` with no model → `session`; old `subagent` + model name → `claude:<name>`; an old `Verifier model` pick → the Tester and Reviewer lines (shared, as it was used). A line malformed under the modern lane grammar is never mapped — BLOCKED stop-and-ask per the error contract below.

## Error contract

All lanes, all roles:

- **Lane unavailable, malformed config entry, auth failure, missing Bash, missing/stale report, unresolvable `claude:<name>`** → **stop-and-ask**: report what failed and what was attempted, wait for the user's instruction. Malformed ≠ unset — a malformed entry is never treated as the default.
- **No silent downgrade anywhere.** Falling back to another lane or to the session default without asking is a contract violation, not resilience.
- **Quota exhaustion mid-run** → BLOCKED with resume-later semantics.
- **404 on a named agent type** (claude lane, resolution step 2) → `general-purpose` fallback **with a user-visible report** — the one sanctioned fallback, because the dispatch axis is preserved.

## Scope

The `roles` lanes apply to Claude Code; other hosts ignore that table. Codex additionally supports the optional native reviewer setting above. No scripts or hooks implement routing; the logic lives in skill text, and this doc is its single source.
