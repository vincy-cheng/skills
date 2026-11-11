# Task outcomes — measurement schema for completed dev-flow runs

Single source of truth for the `## Task outcome` section recorded at close-out (step 11). The section is **measurement-only**: no workflow gate reads it, and it never affects resume logic. Its purpose is retrospective comparison — which model/role configurations completed which kinds of tasks at what cost and quality, so later runs' pre-filled recommendations can carry an `[evidence: …]` tag (see the plan skill's step-5 Roles ask in `skills/new-feature/SKILL.md`).

## Record format

The record is a `## Task outcome` section appended to the feature state file at step 11, before the run is marked done. Fields:

| Field | Content |
|-------|---------|
| **Task boundary** | feat-name, issue number, and the task count from the plan's task list — what this record covers and nothing more. |
| **Difficulty and risk** | The run's Risk tier plus one difficulty class with a one-line assignment reason: **doc-only** (prose/docs, no executable behavior), **guard** (suite fragments, packaging, structural checks), **multi-file integration** (behaviors spanning several files or the workflow shape). |
| **Completion criteria** | The issue's acceptance criteria, by reference (issue number/URL), not restated. |
| **Model and role configuration** | The Roles-block lanes (implementer/tester/reviewer), the saved model fields, the Implementer context pick, and the reasoning setting when the lane exposes one — a lane that does not expose one records `unknown`. |
| **First-pass acceptance** | The test and review verdicts from the first gate round, before any repair. |
| **Repair rounds** | Count and cause, from Tasks annotations and the state file's rewind history. |
| **Unresolved limitations** | Findings noted in the PR and known gaps left open. |
| **Token categories** | Available input, cached input, output, reasoning — each an observed value or `unknown`. No category counts a subset of another (cached input is not re-counted as available input), and no session-wide counter is attributed to one task. |
| **Cost class** | One of **actual billed**, **subscription allowance**, **recorded usage**, **estimate** — the classes stay separate and are never summed across. An estimate cites a checked official price with its check date; an unverifiable price stays `unknown`. |
| **Times** | Three separate fields: task elapsed, measured request latency, observed human rework — each an observed value or `unknown`. Session duration is never recorded as model latency, and human effort is never inferred from time gaps. |

## Collection procedure

For each field, the source and the honesty rule. An unverifiable value is `unknown`, never guessed; a missing source is stated as missing.

| Field | Source |
|-------|--------|
| Task boundary | State file (title/issue references) and the plan's task list. |
| Difficulty and risk | The plan's per-task `Risk:` lines and the state file's **Risk tier**; the difficulty class is assigned at close-out by the definitions above. |
| Completion criteria | `gh issue view` metadata — the issue body's acceptance criteria. |
| Model and role configuration | State file: **Roles block**, **Codex implementer model** / reviewer model fields, **Implementer context**; reasoning setting from the host's dispatch record or `unknown` if the lane does not expose one. |
| First-pass acceptance | Test report (state file **Last verification** from the first round) and review report verdict from the first gate round; reports archived under `docs/features/.test/` and `docs/features/.review/` (step-10 PR-check reports live under `.pr-review/`). |
| Repair rounds | Tasks annotations (`[x]` with repair notes) and the state file's rewind history / PR check entries. |
| Unresolved limitations | The PR body, review report's note-in-PR findings, and close-out observations. |
| Token categories | Host output (the dispatching session's usage readout) for the recorded lane's work; per-task host readouts only where attribution exists — otherwise `unknown`. |
| Cost class | The host/billing surface the user's account runs on: an actual bill → actual billed; a flat plan subscription → subscription allowance with the plan name; an API dashboard count → recorded usage; a computed figure → estimate with the checked official price and its check date; an unverifiable price → `unknown`. |
| Times | Task elapsed from the state file's timestamps, request latency from the host's per-request timing where exposed, human rework from observed user repair actions (messages, fixes) — never inferred from gaps. |

## Comparison rules

Comparisons across `## Task outcome` records:

- **Same difficulty class only** — doc-only vs guard vs multi-file integration are never averaged together.
- **Denominator includes failed and abandoned attempts** — not only successful runs; a configuration's success rate counts what it failed at.
- **Per-successful-task cost, tokens, or time** only when the attribution supports dividing by the successful tasks and the success denominator is stated alongside.
- **State confounders** — role and context differences between runs (implementer lane, shared vs per-task context), sample size, and model-identity uncertainty (gateway naming drift, version changes).
- **An unsupported comparison ends "insufficient evidence"** — never a winner. If the records do not support a claim, say so and stop.

## Recommendation format

Per difficulty class, a recommendation states:

1. **The configuration the evidence supports** — lanes, model fields, Implementer context, and the sample it rests on.
2. **The uncertainty** — sample size, confounders, and the fields that stayed `unknown`.
3. **The quality requirement it was held to** — the gates the sample passed (test, review tiers), because a cheaper configuration that skipped gates is not evidence.

Savings are quantified only when the records support the number; otherwise the recommendation names the direction and ends "insufficient evidence".
