# Model routing — role-level lanes for dev-flow subagent dispatch

Single source of truth for dev-flow's model routing: lane semantics, config schema, availability checks, the thin-driver flow, the sandbox map, commit ownership, and the error contract. Every dispatching skill (`execute-tasks`, `test`, `review`, the plan skill's plan review pass, and the brainstorm viability red-team) points here and never re-derives lane semantics from its own text.

Before composing any native or CLI dispatch brief, load `references/output-style.md` from the plugin root and include its actual contents in the brief. Isolated reviewers and drivers must receive the reference directly; they cannot rely on parent context. Preserve each role's existing report contract and required evidence.

Roles: **implementer** (execute-tasks step 5, one per task), **tester** (test step 6), **reviewer** (brainstorm red-team, plan review, and step-7 main and focused review). Select the host before interpreting routing settings: Codex reviewers follow **Codex reviewer model** (`codex_reviewer_model`) and Codex native implementation follows **Codex implementer model** (`codex_implementer_model`) below; Claude Code uses the lanes below. Tester routing is unchanged.

## Isolated brief boundary

A dispatch brief for implementer, tester, or reviewer has the task, global constraints, relevant paths, exact interfaces from earlier tasks, output-style contents, and the role’s report contract. It has no unrelated conversation history.

Keep one complete copy of each shared rule in that brief. Do not repeat shared guidance elsewhere in the dispatch chain.

Every implementer brief contains six bounded fields: **Goal**, **necessary background**, **boundaries**, **constraints**, **observable acceptance**, and **stop conditions**. Include only context needed to do that task; do not paste the full workflow or full conversation history. A shared worker gets only the changed task-specific delta plus any undelivered required guidance; a per-task worker gets the complete bounded brief.

### One diagnostic recovery for the same issue

When an implementer reports a context gap or an ordinary implementation failure, the coordinator records the **same-issue identity** in the existing execution note and task report: task/authorized goal, original error, underlying cause or fingerprint, diagnostic, revised brief and handoff, whether the one recovery opportunity was used, and its result. Resume reads that record. Renaming or restarting a task/worker does not reset the opportunity for the same underlying issue; a distinct root cause is evaluated separately.

Before revising the brief, confirm that the coordinator can diagnose the reported cause; this diagnostic capability must be established. If that capability is not established, stop and report the gap; do not invent model-strength tiers. When established, diagnose and revise only the bounded brief, then send it as a follow-up to the **original implementer**. Do not automatically change model, context, lane, or backend, and do not take over implementation. If the original worker cannot receive a follow-up, stop and report. One revised handoff is the recovery limit. If it fails, stop and report rather than retrying again. After a successful revised handoff, continue under the original task identity and complete the normal task checks. The independent Tester (step 6) and main Review (step 7) gates still apply.

Quota, identity, permission, model-unavailability, and tool-unavailability errors are immediately **BLOCKED** and do not consume the ordinary diagnostic opportunity. Preserve the original error and stop; never substitute another model, context, lane, or backend automatically. User-directed changes follow the existing explicit-change rules.

Keep full logs and findings in the role’s local report. Keep the transport return concise, but preserve its exit status, the failure details needed for the next action, required evidence, and a usable report/log path. The orchestrator reads the report before acting and presents every decision-relevant finding to the user or next step.

Evidence reuse requires the same evidence type and the required producer, plus the complete evidence tuple: repository, HEAD SHA, Base ref, Base SHA, report path, and relevant working-tree state. Implementation evidence and tester evidence remain separate. Revalidate when code, requirements, or evidence identity changes. Stop instead of advancing on stale evidence, a relevant uncommitted path, a missing report, an unavailable reference, or a failed dispatch.

## While delegated work runs

Use the host's completion notification or a blocking wait for pending workers. Prefer one wait for the pending set when the host supports it. If a timeout is required, use the longest practical host-supported interval for the expected work. A timeout alone does not establish progress or failure. On an unchanged timeout, continue the blocking wait without rereading the worktree, sending a status request, or dispatching a replacement. Check the worktree and reports when a worker finishes, requests help, or reaches a task checkpoint.

For Codex `wait_agent`, allow at most five consecutive waits without material progress across the pending workers. A completion, request for help, or task checkpoint resets the count. After five unchanged waits, rely on completion notifications if the host can resume the coordinator. Otherwise record the pending worker handles in the existing run note and leave the current gate pending. For review batches, also record the round, frozen input identity, routes, and any queued members. Resume from the saved handles under **Review batches**. Do not bypass the cap with another polling tool or restart the workers to reset it.

Within a task, use focused checks during edits and run the required broader checks at the task's verification checkpoint. Reuse an existing result only for the same producer, evidence identity, and relevant working-tree state. Run required independent test and review gates at their normal steps.

## Lanes

A lane value pins where a role's work executes. Four values:

| Value | Meaning | Dispatch shape |
|-------|---------|----------------|
| `inline` | implementer only — the task runs in the current session, no subagent. TDD still applies. | no dispatch |
| `session` | claude lane on the session's default model — today's default shape. | Agent tool, no model pin |
| `claude:<name>` | claude lane on a named model — `<name>` is any name the session's model picker shows (`sonnet`-family names, gateway names like `github/gpt-5.4`, `github/claude-haiku-4.5-high`). | Agent tool via the resolution rule |
| `cli:<tool>/<model>` | an external CLI's exact model ID. Built-in `codex` is native; configured custom tools use the adapter contract below. | thin-driver flow |

Custom CLI tools can be configured in `.dev-flow/config.json` under `cli_adapters`. The resolver command is `python3 scripts/custom-cli-adapter.py resolve --config PATH --lane LANE`. For example:

```json
{
  "cli_adapters": {
    "local": "/absolute/path/to/agent-cli"
  }
}
```

For `cli:local/vendor/model/v2`, the resolver returns the canonical executable path, its SHA-256 digest, adapter name, and exact model ID `vendor/model/v2`. It splits the lane at the first slash and passes values as structured arguments; it does not evaluate a command string. Each configured value must be an absolute executable path, and only the selected entry is checked. Inactive lanes, including `cli:codex/<model>`, return `no-custom-adapter` without reading custom config. The built-in Codex driver keeps its original route. An invalid active custom route exits nonzero, reports the original route, and tells the user to correct `cli_adapters`. Missing config, invalid JSON or schema, an unknown adapter, and an invalid executable all block the route. `codex` is reserved; a same-name config entry cannot override it.

The bridge invokes the executable in two stages, `probe` and `run`. Both use the role's enforced mode and exact selected model. The wrapper returns backend metadata through a separate pipe, and `run` must match a private probe receipt that pins the executable and effective non-secret settings. The driver blocks when it cannot verify the OS sandbox, the observed model, the permission mode, the settings identity, or the backend exit status. It keeps launcher credentials out of evidence and uses only declared environment names. See [Custom CLI adapters](custom-cli-adapters.md) for the schema-v1 metadata contract, wrapper example, permissions, and gateway connection guidance.

## Durable custom CLI attempt interface

The coordinator claims one role work item before launch. This captures the repository head and the exact authorized write paths, including each path's absence or content, Git index entry, and status. Use the saved route on every resume:

```sh
python3 scripts/custom-cli-adapter.py claim \
  --config REPO/.dev-flow/config.json --repo REPO \
  --role implementer --work-item TASK-ID \
  --lane 'cli:adapter/exact-model-id' --write-path REPO/TASK-FILE
```

The command creates a per-work-item lock under `docs/features/.routing/locks/`, the current claim at `docs/features/.routing/claims/<role>/<work-item>.json`, and a private attempt directory at `docs/features/.routing/attempts/<claim-id>/`. It captures Git HEAD and each exact write path's presence, content digest, index entry, and status under the lock. A live or pending claim blocks another claim for the same role and work item. Retry a terminal `failed` claim only after the user authorizes it and the write scope is reconciled. Use `claim --retry-claim CLAIM-ID` with the same work item and route. If a failed Docker run saved changed files, inspect the private recovery manifest and the files it lists. After reconciliation, also pass `--reconciled-recovery SHA256` with the manifest digest recorded in the failed claim. Other terminal dispositions stop that work item. Reviewer claims omit `--write-path`; implementation and test claims list every exact writable task path.

Each probe and run stage gets a separate, single-use authorization. Authorize the stage before starting its `driver` process:

```sh
python3 scripts/custom-cli-adapter.py authorize-stage \
  --repo REPO --role implementer --work-item TASK-ID \
  --claim-id CLAIM-ID --stage probe
```

Start the driver with the same claim, route, settings, role, sandbox, report, receipt, and write paths. Create a private `dev-flow-report-*` directory inside the attempt for the role output. `--stage` selects the fixed `probe` or `run` operation. A run also takes `--brief`. The driver prints a waiting record with its process ID on stderr, then waits at the launch barrier. The coordinator must persist that handle before it binds and releases the driver:

```sh
python3 scripts/custom-cli-adapter.py driver \
  --config REPO/.dev-flow/config.json --lane 'cli:adapter/exact-model-id' \
  --repo REPO --role implementer --sandbox workspace-write \
  --report ATTEMPT-DIR/dev-flow-report-worker/worker-report.md \
  --receipt ATTEMPT-DIR/probe-receipt.json \
  --claim-id CLAIM-ID --work-item TASK-ID --stage probe \
  --authorization-id AUTH-ID --write-path REPO/TASK-FILE
```

```sh
python3 scripts/custom-cli-adapter.py bind-driver \
  --repo REPO --role implementer --work-item TASK-ID \
  --claim-id CLAIM-ID --stage probe --authorization-id AUTH-ID --handle PID
python3 scripts/custom-cli-adapter.py release-driver \
  --repo REPO --role implementer --work-item TASK-ID \
  --claim-id CLAIM-ID --stage probe --authorization-id AUTH-ID --handle PID
```

The driver consumes its authorization under the work-item lock before it starts the adapter. It records the native process identity and verified single-process policy after launch, or records the container and local engine identities before starting that container. Direct `probe` and `run` calls fail. The driver checks that HEAD, route, executable and configuration, role, repository, and exact write scope still match the claim. It checks each file's content, absence, Git index entry, and status before launch. Probe must leave that scope unchanged before the coordinator authorizes `run`. A successful run records the authorized write scope and the actual report identity. Report or baseline validation failure still leaves terminal failure evidence when the driver can verify execution has ended. A consumed or stale authorization cannot start another wrapper.

On interruption, use the original stage authorization to try `settle-stage`. A native stage requires the recorded single-process policy and confirmed absence of its driver and adapter. A container stage requires the recorded engine, container and an absent driver. The controller stops the exact recorded container if it is running. If the driver ended before starting it, the controller removes that unstarted container. It verifies the result before settlement. A write-enabled Docker run keeps its private staging while completion is pending. Settlement preserves its changed authorized files before it records a retryable failure. Missing or unverifiable isolation evidence leaves the claim pending.

```sh
python3 scripts/custom-cli-adapter.py settle-stage \
  --repo REPO --role implementer --work-item TASK-ID \
  --claim-id CLAIM-ID --stage run --authorization-id AUTH-ID
```

After the coordinator reviews the role report and outcome, write `finalization-intent.json` in the attempt directory. Schema v1 includes `claim_id`, `role`, `work_item`, `route`, `repo`, `expected_head`, `outcome`, `report` (`source`, `sha256`), `checkpoint` (`path`, `expected_sha256`, `content`, or null for standalone work), and `commit` (`enabled`, `message`, `paths`, with `path` and `sha256` for each entry). For a completed run with a validated report, use `accepted`, `worker_failed`, `needs_context`, or `rejected` according to the role's judgment. Use `failed` for a launch, transport, permission, identity, or evidence failure. A controller diagnostic in the attempt directory can supply the report for `failed`. Only an accepted implementer result can enable a commit. A checkpoint path must identify an existing workflow state file under `docs/features/.feature-states/`. Commit paths must be captured, clean at claim time, and match their reviewed content digests.

Apply or resume that same intent with one command:

```sh
python3 scripts/custom-cli-adapter.py finalize --intent ATTEMPT-DIR/finalization-intent.json
```

The command takes the work-item lock and verifies the report and expected checkpoint before recording pending intent. All worker outcomes require a completed run with the same report and current write-scope evidence. Under the same lock, it cancels any unused stage authorization, commits only the exact approved task paths when authorized, promotes the report, updates the workflow checkpoint, and records a terminal disposition. It uses the normal Git commit path and preserves unrelated staged changes. It verifies the reviewed working-tree bytes and executable bit. Before staging, it records the expected Git entry for each approved path, including the Git mode and blob identity after content normalization. Both the index and committed tree must match those entries. Resuming the same intent recovers a matching commit or checkpoint without another launch or commit. If the observed effects do not match the intent, the claim remains pending.

`session` is the claude lane's unpinned shorthand, not a separate lane. Tester/reviewer are separate picks — pre-filled identically at the combined ask, each line independently overridable by the user in that same turn.

## Custom CLI dispatch

Resolve the active host and role route first. Follow **Thin-driver flow** for `cli:codex/<model>`. For a selected `cli:<tool>/<model>` with a different tool name, use [Durable custom CLI attempt interface](#durable-custom-cli-attempt-interface).

| Host | Roles that can select a custom route |
|------|--------------------------------------|
| Claude Code | Implementer, tester, and reviewers for red-team, plan, main, focused, and the Step 8 documentation supplement |
| Codex | Implementer and tester. Reviewer selection stays native Codex. |

Use a fresh isolated driver for the selected host. On Claude Code, use the session driver. On Codex, use a session-default native driver. The driver carries the role's verbatim report contract and the shared output style. Confirm the host can start a local process, read its waiting record, and let the coordinator bind and release that same process. A custom implementer is one-shot. Reject a saved `shared` context before launching and retain the user's pick.

1. Resolve the helper at `scripts/custom-cli-adapter.py` relative to the installed plugin root. Use a compatible Python 3 interpreter. Verify the configured execution boundary before dispatch. The default native runtime uses macOS `sandbox-exec` and denies process creation. An adapter that needs subprocesses can opt into the [pinned Docker runtime](custom-cli-adapters.md#execution-isolation). If the host cannot establish its configured boundary, report the original blocker and keep the gate pending.
2. Pin the repository, role, saved route, current options and exact write paths. Give each task, gate attempt, or review member its own stable work item. Use the target checkout's ignored routing directory. Reuse its current claim on resume. Create a new one only when its prior disposition permits it.
3. Run the probe and role stages through the helper. For each stage, capture the waiting driver handle, use `bind-driver` to persist it, then use `release-driver`. Wait for the same process to finish. Keep the sandbox and scope fixed. Implementers get their authorized task files and report. Testers get the assigned report and any explicitly authorized workspace files. Reviewers return the full report on stdout, which the helper saves verbatim.
4. The coordinator applies the role's existing judgment to the report. For an implementer, [review the pending task changes](#review-a-custom-implementer-result) before supplying the approved intent. Only an authorized implementer intent may commit. Use `finalize --intent` for first publication and interrupted recovery. For an in-flow run, supply the existing state file and the approved checkpoint content. The orchestrator still owns Goal status changes and index mirroring. For a standalone role with no state file, use a null checkpoint. Read the terminal disposition and use its accepted report as the source for the role's established report destination. Reuse a matching destination. Preserve a conflicting report for reconciliation.
5. Preserve the selected route, evidence and changed files on failure. A missing tool, permission, exact model match or valid report blocks the selected route without fallback. Try `settle-stage` for an interrupted consumed launch with recorded process identity. Only an explicitly authorized and reconciled `failed` disposition allows a new attempt of the same work item and route. A completed worker's failure, context request, or rejection stops that work item.

### Review a custom implementer result

Before finalization, use the active claim and completed run to review the authorized working-tree changes.

1. Verify HEAD equals the claim's `head_sha`. Match each authorized path in the claim's `write_paths` with its `stages.run.post_baseline` entry. Compare file presence, content digest and executable mode. Confirm the live files match the run evidence and each `index_entry` still matches the claim.
2. Read each changed file directly. For a previously tracked file, compare it with the blob recorded in its baseline `committed_entry`. Read the raw blob with `git --no-pager cat-file blob <object-id>`. Read authorized new files in full. Review executable-mode changes even when the file bytes match.
3. Apply the task's review criteria before writing the finalization intent. List only the exact reviewed paths and digests in the commit intent. Each commit path must have been clean at claim time. If the evidence differs from the live checkout or the result cannot be reviewed, keep acceptance pending and reconcile it. If the task review rejects a completed result, finalize it as `rejected` under the one-shot contract.

## Resolution rule (`claude:<name>`)

The dispatching skill resolves `<name>` against the session's model list, in this order:

1. **Model-param family name** (`sonnet`, `opus`, `haiku`, `fable` families) → dispatch with the Agent tool's `model` param.
2. **Gateway/agent-type name** (anything else the picker shows, e.g. OmniRoute names) → dispatch via `subagent_type`. The agent-type list is session-scoped: confirm the type exists before dispatch. A named type that 404s follows the role-specific 404 rule in **Error contract**.
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

For CLI reviewer lanes, the external reviewer stays in the read-only sandbox and returns its complete report through output. Its driver captures and saves that report verbatim to the assigned report destination, without judging or summarizing findings. For [custom CLI dispatch](#custom-cli-dispatch), bind each attempt to the step, round and member index. Briefs, captured output, and other transient files stay in that reviewer's unique directory. Keep existing implementer and tester writer contracts unchanged.

Before the first dispatch in a batch that includes custom CLI reviewers, run the helper's `identify --config REPO/.dev-flow/config.json --lane 'cli:adapter/exact-model-id'` for each custom route from the same local environment used for execution. Save its exact route and `identity_sha256` by member index alongside the batch's frozen inputs. The identity covers the canonical executable path and content, selected route configuration, declared non-secret environment and files, and fixed runtime policy. Credential values are excluded. Pass that member's saved digest to `claim --expected-identity SHA256` for every custom reviewer claim. The helper checks it both when claiming and when starting each stage.

On resume, before dispatching a queued member, and before accepting the aggregate, recheck every custom member with `identify --expected-identity SHA256` and its saved route. Verify that each completed custom member's claim carries the frozen digest for its index and binds the expected report. A missing digest, changed identity, or failed recheck invalidates the whole incomplete round. Preserve the old reports and handles for diagnosis and reconciliation. Once the old attempts are settled, a fresh round takes fresh identities and attempts on the saved routes.

Use `docs/features/.review/<feat>/batches/<step>/round-<N>/reviewer-<I>.md` for individual reports, with one-based numeric indices and no model names in paths. Standalone mode uses the review skill's existing feature naming convention. Existing single-reviewer destinations remain compatible. Red-team and plan-review aggregates go in their existing pass sections. Main and focused review keep their existing aggregate report destinations and archives. Record each route, index, verdict, findings, reviewed material identity, round, and any adjudication exception.

Every member must return a current valid report. A failed or incomplete batch cannot clear the gate. Preserve valid partial findings without claiming clearance. A dispatch error is never a fallback vote. On resume, first recover any saved pending batch, including one paused at the wait cap. Verify its frozen inputs and selected routes still match, collect reports and completions from the saved handles, and dispatch only members that were still queued. If there is no recoverable batch, or it failed or became stale, use a fresh complete batch and current routing once the blocker is resolved. Do not reuse approvals across rounds or changed materials, and persist batch identity in local reports without adding lifecycle statuses.

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
- **404 on a named agent type** (claude lane, resolution step 2) → **BLOCKED** for an implementer or a review-batch member. Preserve the original error. The legacy `general-purpose` fallback remains available only for a single verifier dispatch outside a review batch, with a user-visible report.

## Scope

Claude Code uses the `roles` lanes. Codex uses its native reviewer and implementation settings where applicable and supports explicitly selected external lanes for implementers and testers. This reference owns role routing. The custom CLI helper applies the permission, evidence and recovery contract for the selected external lane.
