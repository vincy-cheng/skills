---
name: brainstorm
description: >-
  Use when designing or exploring a feature or fix before building it — turn an idea
  into a validated design and spec through collaborative dialogue. Runs standalone in
  any repo, or as the engine of dev-flow step 1 (invoked by the new-feature command).
---

# Brainstorming

Turn an idea into a validated design and a written spec — through collaborative dialogue, never implementation.

**Core principle:** No implementation action until your human partner approves the design.

Run standalone in any repo, or invoked by `dev-flow:new-feature` (step 1) inside a dev-flow run. Either way the dialogue is the same.

## The Iron Law

```
NO IMPLEMENTATION ACTION BEFORE EXPLICIT DESIGN APPROVAL
```

No code, no scaffolding, no project setup, no "small start" — nothing that changes the system until your human partner says yes to the design.

**What scales with the task is the artifact — never the approval.** A todo list or a config change still gets a design presented and approved; it may be two sentences in chat, but the gate never drops.

## Three paths

Classify the request before your first question and say the classification out loud, so your human partner can override it:

- **Spike** — a feasibility question whose output is an answer, not code you keep. Present the question and probe plan in 2-3 sentences, get a nod, investigate cheaply, report a recommendation. Anything built stays labeled throwaway.
- **Bounded** — a well-scoped change to a flow that already exists in this repo (a new flag, a small endpoint, a one-file fix). Ask the clarifying questions that matter, present a short design in chat, get explicit approval.
- **Architectural** — new projects, new subsystems, changes that restructure how components fit together. Full process: questions, approaches, sectioned design, written spec.

When in doubt between two paths, take the heavier one. **The ratchet is one-way:** hidden complexity discovered mid-task upgrades the path — stop, say so, step up. Nothing downgrades.

**In dev-flow, every path still writes the spec doc** (see Spec output below) so the next step has its artifact — the path scales how much dialogue precedes it. Standalone, a spike's terminal state is a reported recommendation and a bounded task's is the approved in-chat design; a user asking to keep spike output is a new request — classify it.

## Interview

Anchor the dialogue before design work. Ask directly, one at a time, multiple-choice when possible:

1. **What problem are we solving?**
2. **Feature or fix?** (in dev-flow this confirms the run's **Kind** — the orchestrator sets it at state-file creation and passes it in the brief; standalone with no brief, this question asks and carries it forward itself)
3. **Scope boundaries** — what's in, what's out?
4. **What does success look like?**

The answers become the brief for the design dialogue.

**A brief may already exist** — passed in by the caller, or established in an earlier conversation. Confirm it, don't re-derive it: restate problem/kind/scope/success as received and ask only what's genuinely open.

## Idea-folder ingestion

If the arguments reference an idea folder (`ideas/[<project>/]<slug>/`, the output of `dev-flow:new-idea`) and it exists, read its docs **before** anything else and treat them as the established brief — don't re-derive what's settled:

- `README.md` → problem/goal — the starting brief, carried forward.
- `design.md` → proposed approach — the starting point for design decisions; settled choices aren't re-litigated.
- `cost.md` → constraints — a decided tier/price is a spec constraint, not an open question (may be absent; proceed without it).
- `plan.md` → milestone shape — seeds the approach discussion; still refined here, not copied.
- `research.md`, `tl-dr.md` → background; load on demand.

Record the folder path in the state file's References (in a dev-flow run). The interview trims to confirmation: restate problem/kind/scope/success as read from the folder and ask only "did I read this right?" plus anything genuinely open. The folder docs don't close the design dialogue — they open it further along.

If the path doesn't exist, say so and proceed as a normal fresh start.

## Explore before asking

Facts are your job, never your human partner's. Before asking design questions, check the current project state: files, docs, recent commits. Anything you could look up yourself, look up — bring findings to the dialogue, don't ask the user for them. Where existing code has problems that affect the work (a file grown too large, unclear boundaries), include targeted improvements as part of the design — but no unrelated refactoring.

## The design tree

Map the design as a **tree**: every decision branches into the decisions that hang off it. Work the tree in **rounds**.

The **frontier** is every decision whose prerequisites are already settled — the questions you can ask *now* without guessing at answers you haven't heard. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body>
```

Each round's answers reshape the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute and ask the next round. A question whose answer depends on another question still open in this round belongs to a *later* round, not this one.

The session is done when the frontier is empty: every branch visited, nothing left silently assumed.

**Flag decomposition early.** If the request spans multiple independent subsystems, flag it *before* spending questions on details: help decompose into sub-projects (what are the pieces, how do they relate, what order), then brainstorm the first sub-project through the normal flow. Each sub-project gets its own spec → plan → implementation cycle.

## Approaches

Once you understand what you're building, propose **2-3 approaches** with trade-offs. Present them conversationally, lead with your recommendation and reasoning. **YAGNI ruthlessly** — remove unnecessary features from every approach before presenting.

## Presenting the design

Present the design in sections scaled to their complexity — a few sentences if straightforward, a couple of paragraphs if nuanced. Ask after each section whether it looks right so far. Cover: architecture, components, data flow, error handling, testing.

**Design for isolation:** break the system into units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently. For each unit you should be able to answer: what does it do, how do you use it, what does it depend on? If you can't change the internals without breaking consumers, the boundaries need work.

## Spec output

Write the validated design to:

```
docs/features/specs/YYYY-MM-DD-<feat-name>-design.md
```

(dev-flow conventions: always under `docs/features/` — never `docs/superpowers/`; the spec is never committed.)

Then self-review the spec with fresh eyes, fixing inline:

1. **Placeholder scan:** any "TBD", "TODO", incomplete sections, vague requirements?
2. **Internal consistency:** do sections contradict each other?
3. **Scope check:** focused enough for a single implementation plan, or does it need decomposition?
4. **Ambiguity check:** could any requirement be read two ways? Pick one and make it explicit.

Then ask your human partner to review the spec file. Changes requested → revise, re-run the self-review, re-present. **The spec is approved when they say so — not when it's written.**

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to need a design" | Simple means a *short* design, not no design. Two sentences in chat, then approval. |
| "I'll call it bounded and skip the spec" | Reaching for a label to skip work IS the doubt — take the heavier path. |
| "The design is obvious — I'll start while they read it" | The gate is the approval, not the design's length. Present, then stop until you hear yes. |
| "I understand this kind of app, so it's bounded" | Bounded measures the repo, not your familiarity. A new project has no existing flow — it's architectural. |
| "The spike works, so I'll keep the code" | A spike's output is an answer. Keeping the code is a new request — classify it. |
| "It grew, but I'm almost done — no need to re-classify" | Hidden complexity upgrades the path mid-task. Stop and say so. |
| "They approved the spike, so the follow-up change is approved too" | Each task gets its own classification and its own approval. |

## dev-flow integration

**Standalone mode:** any repo, no state file needed — dialogue + spec output apply to the task at hand.

**In-flow mode:** invoked by `dev-flow:new-feature` step 1. In-flow rules:

- **No handoff.** This skill never advances, skips, or reorders dev-flow steps, and never invokes the plan skill or any other skill. Its terminal state is the approved spec; control returns to the orchestrator; step order is governed solely by the hard gate in `commands/new-feature.md`.
- Specs are never committed. Artifacts stay under `docs/features/` — never `.superpowers/`.