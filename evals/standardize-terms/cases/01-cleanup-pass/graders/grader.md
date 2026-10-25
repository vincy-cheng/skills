---
type: llm
---
You are grading a single-turn response from an agent that may or may not have
the `standardize-terms` skill loaded. Grade in two layers, in order. Be strict
and binary — no vibe scores.

## Layer 1 — Behavior (binary, must ALL pass)

- B1. The response proposes prose rewrites (before → after pairs, or a plan
  listing the rewrite categories) BEFORE applying any edit — it does not
  silently rewrite the doc end-to-end and present the result as done.
- B2. The rewrites address at least two of these three violation classes
  present in the doc: (a) vague quantifiers / filler ("several", "appropriate",
  "It should be noted that"); (b) one long run-on sentence (the error-path
  sentence, ~40 words); (c) synonym drift ("module" / "component" /
  "cache element" for one concept).
- B3. The response honors the guided interaction: it asks or waits for a
  choice (apply all / by category / cancel) OR presents the proposals as
  awaiting confirmation — a response that applies everything with no
  confirmation step fails.

## Case-specific — never-touch regions (binary, must ALL pass)

These regions of the doc are never rewritten. If the response edits (or
proposes to edit) any of them, FAIL immediately:

- N1. The `must reject unknown slugs` sentence — the modal `must` is frozen;
  it stays, unmodified.
- N2. The `will be discarded after 24 hours` sentence — the modal `will` is
  frozen; the sentence may gain clarity around it, but `will` is not swapped
  to `must`/`shall`/`may` and the sentence is not shown as a passive-to-active
  fix with an invented agent.
- N3. The checkbox lines `- [ ]` (requirements and tasks) — unchanged.
- N4. The `Risk: high — executable-code` line — unchanged.
- N5. The YAML frontmatter (`title: Slug cache`, `status: draft`) — unchanged.
- N6. The Python code fence — byte-identical content.

## Layer 2 — Quality (rubric, 0–2 each; only if Layer 1 is fully passed)

- Q1. Category organization (0–2): 0 = an undifferentiated wall of edits;
  1 = grouped but without counts or cap discipline; 2 = grouped by rule
  category with per-category counts and a preview cap respected.
- Q2. Agent discipline (0–2): 0 = invents agents ("we merge the files");
  1 = converts one deliberate passive unnecessarily; 2 = active rewrites
  name only agents present in the original, deliberate passives left alone.

## Verdict

Report: Layer 1 as `B1..B3: Y/N` each with evidence, N1..N6 as `preserved /
MODIFIED` each, then Q1/Q2 scores. Overall PASS iff all of Layer 1 is Y AND
all N-items are preserved. State `PASS` or `FAIL` on the first line.