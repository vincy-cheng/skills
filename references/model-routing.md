# Model routing — role-level lanes for dev-flow subagent dispatch

Single source of truth for dev-flow's model routing: lane semantics, config schema, availability checks, the thin-driver flow, the sandbox map, commit ownership, and the error contract. Every dispatching skill (`execute-tasks`, `test`, `review`, the plan skill's plan review pass, and the brainstorm viability red-team) points here and never re-derives lane semantics from its own text.

Before composing any native or CLI dispatch brief, load `references/output-style.md` from the plugin root and include its actual contents in the brief. Isolated reviewers and drivers must receive the reference directly; they cannot rely on parent context. Preserve each role's existing report contract and required evidence.

Roles: **implementer** (execute-tasks step 5, one per task), **tester** (test step 6), **reviewer** (brainstorm red-team, plan review, and step-7 main and focused review). Select the host before interpreting routing settings: Codex reviewers follow **Codex reviewer model** (`codex_reviewer_model`) and Codex native implementation follows **Codex implementer model** (`codex_implementer_model`) below; Claude Code uses the lanes below. Tester routing is unchanged.

## Isolated brief boundary

A dispatch brief for implementer, tester, or reviewer has the task, global constraints, relevant paths, exact interfaces from earlier tasks, output-style contents, and the role’s report contract. It has no unrelated conversation history.

Keep one complete copy of each shared rule in that brief. Do not repeat shared guidance elsewhere in the dispatch chain.

Keep full logs and findings in the role’s local report. Keep the transport return concise, but preserve its exit status, the failure details needed for the next action, required evidence, and a usable report/log path. The orchestrator reads the report before acting and presents every decision-relevant finding to the user or next step.

Evidence reuse requires the same evidence type and the required producer, plus the complete evidence tuple: repository, HEAD SHA, Base ref, Base SHA, report path, and relevant working-tree state. Implementation evidence and tester evidence remain separate. Revalidate when code, requirements, or evidence identity changes. Stop instead of advancing on stale evidence, a relevant uncommitted path, a missing report, an unavailable reference, or a failed dispatch.

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
  "codex_reviewer_model": "<available-native-model>",
  "codex_implementer_model": "<available-native-model>"
}
```

- `codex_reviewer_model` is an optional top-level string for Codex reviewers only. Replace the example placeholder with the exact requested model name, or omit the key for the session default. See **Codex reviewer model** below.
- `codex_implementer_model` is an optional top-level string for Codex native implementation subagents only. Its validation, saved-choice grammar, and dispatch rules are in **Codex implementer model** below.
- On Claude Code, each `roles` key maps a role to a lane value from `## Lanes`; the remaining lane rules in this section apply to that host.
- Omitted role → that role behaves exactly as before (implementer: the current default flow; tester: session; `reviewer`: session for all three judgment roles it feeds — step-7 review per the step-5 ask; brainstorm red-team and the plan review pass pinned to `session` directly).
- The whole `roles` key omitted → zero-change default.
- A **malformed** value (unknown role, unknown lane syntax, empty) is NOT unset — it is a BLOCKED stop-and-ask per `## Error contract`.
- Config is the long-term default; per-run picks live in the state file's Roles block. No per-task overrides in v1.

## Codex reviewer model

On Codex, ignore the `roles` table and state-file lane values when selecting reviewer models, even if those Claude lane values are malformed. On Claude Code, ignore `codex_reviewer_model` and keep the existing reviewer lane and external CLI behavior. The dev-flow Roles-presence gate still applies; this rule changes model selection, not the step-5 ask.

For a step without a `codex_reviewers` override, before every fresh reviewer dispatch, including re-review, resolve this setting for brainstorm red-team, plan review, and step-7 main and focused review. A configured per-step list takes precedence as described in **Per-step reviewer groups**. Standalone Codex review and plan review use the same config read, without a Claude lane ask.

1. Read `.dev-flow/config.json` from the target repo. A missing file or absent key means the session default: omit the native `model` argument. An existing unreadable file, malformed JSON, or a non-object top level is invalid config, not an absent setting.
2. A present `codex_reviewer_model` must be a nonempty string. Reject empty or whitespace-only strings, null, boolean, number, array, and object values. Apply **Native model validation** below; do not trim, translate, or guess model aliases.
3. Pass the validated string as the native subagent `model` parameter. Use fresh isolated context (`fork_turns: "none"` where exposed); read-only judgment and existing report contracts still apply. Follow the current tool's reasoning-effort rules independently; this setting adds no effort option.

**Failure:** invalid config, an authoritative restriction that excludes the requested model, or a native tool that cannot accept a string model parameter → **BLOCKED**, no reviewer dispatch. A dispatch that rejects the exact requested model is also **BLOCKED** after preserving the tool's original reason. Show the key, failure reason, and correction/resume hint, then wait for the user. Never retry on another model, use a Claude lane or CLI driver, or silently substitute the session default. Leave the workflow status in place for resume.

Record a configured model in the role's existing pass/report artifact. Re-resolve before the focused reviewer too; it shares this setting with the main reviewer, not a separate model source. This key never selects implementer or tester models.

## Per-step reviewer groups

Optional `codex_reviewers` and `reviewers` objects in `.dev-flow/config.json` map review steps to ordered reviewer lists:

```json
{
  "codex_reviewers": {
    "red_team": ["gpt-6.1-sol", "glm-5.3:cloud"],
    "plan_review": ["gpt-6.1-sol"],
    "main_review": ["gpt-6.1-sol"],
    "focused_review": ["gpt-6.1-sol", "glm-5.3:cloud"]
  },
  "reviewers": {
    "red_team": ["session", "claude:glm-5-3"],
    "plan_review": ["session"],
    "main_review": ["session"],
    "focused_review": ["session", "claude:glm-5-3"]
  }
}
```

The supported step keys are `red_team`, `plan_review`, `main_review`, and `focused_review`. Select the host before reading these objects: Codex uses `codex_reviewers` and ignores `reviewers`; Claude Code uses `reviewers` and ignores `codex_reviewers`. A configured list overrides that step's prior reviewer selection. An absent step follows its existing host and step source, including state-file picks and standalone asks. On Codex, legacy fallback remains `codex_reviewer_model`, then the session default. On Claude Code, preserve the existing lane syntax and state/config/standalone precedence. An unavailable legacy choice does not block a valid active-host override. Implementer and tester routing are unchanged.

Validate the active-host object before routing. It must be an object with only recognized step keys; each present value must be a nonempty array of valid, nonblank strings with no exact duplicate entries. Empty arrays never skip a required review. Reject malformed JSON, unreadable config, wrong value types, blank strings, duplicate routes, unknown keys, and invalid lanes. Ignore malformed inactive-host reviewer settings. Validate every selected route before dispatch begins, then check availability again before each queued dispatch. Keep exact native model names and apply **Native model validation** and the existing Claude lane resolution rules. An authoritative native restriction, unavailable lane/model, failed dispatch, or missing report blocks without a fallback vote.

## Review batches

A review batch is the complete resolved route list for one step and round. Before dispatch, the orchestrator saves exact spec, plan, or design input bytes under `docs/features/.routing/<feat>/<step>/round-<N>/inputs/`. Code review also pins base and HEAD and saves the complete reviewed diff, including relevant uncommitted changes. Every reviewer receives those same frozen inputs in a fresh independent context and cannot read peer findings before returning. Dispatch concurrently up to available host slots, then queue remaining reviewers; preserve the full configured count and never exceed host concurrency.

Each reviewer and driver uses a unique directory: `docs/features/.routing/<feat>/<step>/round-<N>/reviewer-<I>/`, where reviewer indices start at one. The orchestrator alone writes aggregate reports. Before accepting an aggregate, compare live source inputs and the pinned diff with the frozen batch inputs. Any substantive change invalidates the complete batch. Write generated pass sections only after this acceptance check; recording those results alone does not invalidate the accepted round.

For CLI reviewer lanes, the external reviewer stays in the read-only sandbox and returns its complete report through output. Its driver captures and saves that report verbatim to the assigned report destination, without judging or summarizing findings. Briefs, captured output, and other transient files stay in that reviewer's unique directory. Keep existing implementer and tester writer contracts unchanged.

Use `docs/features/.review/<feat>/batches/<step>/round-<N>/reviewer-<I>.md` for individual reports, with one-based numeric indices and no model names in paths. Standalone mode uses the review skill's existing feature naming convention. Existing single-reviewer destinations remain compatible. Red-team and plan-review aggregates go in their existing pass sections. Main and focused review keep their existing aggregate report destinations and archives. Record each route, index, verdict, findings, reviewed material identity, round, and any adjudication exception.

Every member must return a current valid report. A failed or incomplete batch blocks; preserve valid partial findings for diagnosis without claiming clearance. A dispatch error is never a fallback vote. Resume an incomplete step with a fresh complete batch and current routing. Do not reuse approvals across rounds or changed materials, and persist batch identity in local reports without adding lifecycle statuses.

Apply each step's existing verdict rules: a red-team FUNDAMENTAL finding blocks; plan review requires every reviewer to pass; R5 aggregates red before yellow, blue, then green. Deduplicate displayed findings while preserving author attribution, original verdicts, and dissent. An explicit user adjudication records the user's reason as a visible exception. It does not claim unanimous approval and cannot waive unrelated blockers or dispatch failures.

## Codex implementer model

The optional top-level `codex_implementer_model` setting in `.dev-flow/config.json` applies only when a Codex host is ready to dispatch a native implementation subagent. Choose the host and execution path before interpreting this setting. On Claude Code, ignore the setting—including malformed values—and retain every existing `roles.implementer` lane and external CLI behavior; tester and reviewer routing are unchanged. On Codex, `inline` executes the implementation in the current session, `session` dispatches a native implementation subagent, and an explicit `cli:<tool>/<model>` lane keeps its existing thin-driver behavior. Do not reinterpret `claude:<name>` as a native Codex model: an unsupported host/lane combination blocks with a correction hint.

A saved run choice precedes configuration: the user's confirmed execution choice can override an already configured default—including an unavailable default that is inactive—and the saved selection survives later config edits without changing the config. Record it in the optional `Codex implementer model` state field outside the Roles block; consumers point here for the grammar. For native execution, record the exact selected model or `_(session default)_`. For an explicit inline or CLI choice, record `_(not used — inline)_` or `_(not used — cli)_`. A legacy or missing field denotes an older or unconfirmed run; it never authorizes a silent change to execution mode or model and the run retains its stored mode: retain the state's stored mode, and ask before adopting a configured key. A change to a saved choice requires the user's explicit request.

Validate config JSON/root/schema/type before implementation task work, then validate the active confirmed or saved selection per **Native model validation** below. An unreadable config file, malformed JSON, or a non-object top level is invalid config, not an absent setting. A present `codex_implementer_model` must be a nonempty string that is not whitespace-only; reject any non-string value, including null, boolean, number, array, and object values, plus empty and whitespace-only strings. Do not trim aliases or translate model names. Validate a selected native implementation model before every native implementation dispatch and retry. If the active path is inline or CLI, acknowledge that the native setting is unused and do not reinterpret the lane; an unavailable inactive configured default does not block an active saved or unrelated lane choice.

For native execution, pass the validated string exactly as the native subagent `model` argument. When the user confirms a session default, omit `model`; use fresh isolated context, including `fork_turns: "none"` where the native tool exposes it. Revalidate the authoritative restriction and tool support before every native dispatch and retry, per **Native model validation**. An authoritative restriction, unsupported pinning, invalid config, or a rejected native dispatch produces **BLOCKED** with no fallback; preserve the dispatch error's original reason. Report the setting, cause, and correction/resume hint, then leave the workflow status and task progress honest. Never switch the model, execution mode, lane, or backend silently.

## Implementer context

The Implementer's context lifecycle is a separate pick from the lane and the model — all three are selected in the same combined ask, explained with their trade-offs, and recorded per run. Three values:

| Value | Meaning |
|-------|---------|
| `shared` | one implemented context carries across the task loop — the first task starts a worker, each later task is a follow-up to that same worker |
| `per-task` | the existing default shape — every task gets a fresh, isolated worker with only that task's brief |
| `not-used` | inline — nothing to choose; the loop runs in the orchestrator's session |

Recommendations, presented as trade-offs the user decides — never chosen for the user: when a run pins a lightweight model and later tasks are related to earlier ones, recommend `shared` (context reuse is where the lightweight model needs the most help); when no model difference matters and tasks are tightly coupled, recommend `inline`; when a task needs isolation from earlier conversation state, recommend `per-task`. The orchestrator (step 5, dev-flow mode) or the standalone `## Choose a mode` ask confirms the pick; no new config key, lane, or settings frame exists for it. A saved per-run choice beats any later default and is recorded in the state file's **Implementer context** field; resume and repair read it and never re-ask.

Legacy state: the field missing on an old subagent run keeps `per-task` — that was its actual shape; read-only, never migrated on disk. An unknown field value (anything outside the three above) **stops** — BLOCKED stop-and-ask per the error contract; it is never treated as unselected or defaulted. The existing no-switch rule extends to context: mid-run switching between `shared` and `per-task` requires the user's explicit direction, like a model or lane switch.

**Host capability gate — before `shared` starts.** `shared` requires the host to actually provide same-worker follow-up/resume with the selected model's capabilities; Codex native, Claude native (the Agent tool's session-continuation support, e.g. SendMessage resume), and CLI drivers are each judged by their current tooling — never assumed. A CLI lane re-running the same model per task is a sequence of per-task work, not `shared`. Verify before the dispatch loop starts; a capability gap → **stop-and-ask**, listing the explicit alternatives (`per-task`, `inline`) for the user to choose — never a silent downgrade to the run's other modes.

The existing fresh-context rules (`fork_turns: "none"` and the isolated-brief boundary's history rule) scope to `per-task` and to a new worker's first dispatch; a `shared` follow-up receives the accumulated context by design and is not their subject. No cross-session worker service exists — the worker handle and task scope live in the run's existing execution note, and #107's context rules govern what a dispatch carries.

## Native model validation

Treat a tool's explicit, enforced allowlist or schema enum as authoritative: if it excludes the requested model, stop **BLOCKED** before dispatch. A displayed model-options list is only an example unless the tool identifies it as enforced; absence from that list alone does not establish unavailability. Do not hardcode a model availability list in the plugin. If the native tool accepts a string `model` parameter and no authoritative restriction excludes the exact requested name, pass that name unchanged and attempt dispatch. If the tool cannot accept or pin the requested string, stop **BLOCKED** before dispatch. If dispatch itself rejects the name, stop **BLOCKED**, preserve the original rejection reason, and tell the user how to correct the actual cause. For a provider-not-enabled rejection, explain that the user must enable or configure access for the exact requested provider/model; do not invent credentials or settings or promise availability. After the user's correction or explicit resume, revalidate and retry the unchanged exact selection. Never auto-correct user configuration or retry immediately. Never fall back or substitute another model.

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
4. The external model reads the brief and does the role's work. Implementers and testers write their existing report artifacts. A reviewer returns its complete report through output; its driver saves that report verbatim to the assigned report destination. Keep existing single-reviewer destinations compatible.
5. The driver reads the report and relays a **per-role payload**:
   - **implementer:** status + commits + one-line test summary — and the report itself must contain the RED-phase test output **verbatim** (test-first attribution survives the one-shot invocation). Missing/stale report file = hard failure → BLOCKED.
   - **tester:** green/red verdict + failure list.
   - **reviewer:** verdict + **full findings verbatim** — the R5 yellow choice (fix-now vs note-in-PR) must reach the user uncompressed. The driver transports findings without judging or summarizing them.
   - Missing/stale report file for any role = hard failure → BLOCKED stop-and-ask. For reviewer reports, the driver writes the captured output; the read-only reviewer does not create files.
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

The `roles` lanes apply to Claude Code; other hosts ignore that table. Codex additionally supports the optional native reviewer and implementation settings above. No scripts or hooks implement routing; the logic lives in skill text, and this doc is its single source.
