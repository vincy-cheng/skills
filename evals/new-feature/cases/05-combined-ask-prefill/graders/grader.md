---
type: llm
---
# Grader — dev-flow step 5 combined Roles ask (config pre-fill)

You are grading a single-turn response from an agent that may or may not have
the `dev-flow:new-feature` skill loaded. The user's message narrates a dev-flow
run at step 5 entry (status `issue`) with a config-seeded roles table and asks
the agent to take the next step. Grade in two layers, in order. Be strict and
binary — no vibe scores.

The skill's contract (step 5, combined Roles ask): **before** invoking
`dev-flow:execute-tasks`, the orchestrator presents ONE combined ask covering
all three state-file roles — Implementer, Tester, Reviewer — each line
pre-filled from the config's `roles` (tagged as config-seeded or equivalent),
overridable by the user in the same turn. The picks get written to the state
file's Roles block before any dispatch. Steps 6/7 never ask about models — but
that's not this turn's subject; the subject is the combined ask and no early
dispatch.

## Layer 1 — Behavior (binary, must ALL pass)

Check the response against each item; answer Y or N with the quoted evidence
line:

- B1. The response presents ONE user-facing ask turn covering all three roles
  (Implementer, Tester, Reviewer) — one question turn, not three separate
  questions sent to the user one after another across turns. Phrasing is free;
  coverage is the assertion.
- B2. Each pre-fill matches the config: Implementer `claude:github/gpt-5.4`,
  Tester `session`, Reviewer `session` (the red-team role is config-only and
  NOT part of the state-file ask — asking about it here is a minor flaw, see
  Q-layer; omitting it is correct and must not fail B2).
- B3. The pre-fills are visibly sourced from the config (a `[config]` tag,
  "from your config", or equivalent provenance wording — any formulation
  counts).
- B4. The response does NOT dispatch any subagent or invoke execute-tasks with
  dispatches in this turn — the ask comes first; the picks must be user-
  confirmed/written to the state file before dispatch. Starting task work,
  writing task code, or dispatching implementers in this turn fails.
- B5. The response does not ask separate per-step model questions reserved for
  steps 6/7 (there is no separate "verifier model" or "tester model" prompt —
  tester/reviewer were part of the combined ask; a second distinct model ask
  in the same turn fails).

## Gate-violation rule (deterministic)

If the response dispatches any implementer/tester/reviewer subagent, or
skips the ask entirely ("proceeding with the config values") without
presenting the combined ask to the user, it FAILS regardless of anything
else it says.

## Layer 2 — Quality (rubric, 0–2 each)

Only if Layer 1 is fully passed, score:

- Q1. Ask quality (0–2): 0 = bare list with no recommendation framing;
  1 = pre-fills shown but no override affordance mentioned;
  2 = pre-fills + provenance + explicit per-line override affordance ("change
  any line").
- Q2. Workflow placement (0–2): 0 = muddled about what happens after the ask;
  1 = vague "then we execute"; 2 = explicitly frames that picks are written to
  the state file's Roles block and execute-tasks then works the plan per the
  Implementer line's lane.

## Verdict

Report: Layer 1 as `B1..B5: Y/N` each with evidence, then Q1/Q2 scores.
Overall PASS iff all of Layer 1 is Y. State `PASS` or `FAIL` on the first line.