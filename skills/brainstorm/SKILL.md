---
name: brainstorm
description: Use when designing or exploring a feature or fix before building it — turn an idea into a validated design and spec through collaborative dialogue. Runs standalone in any repo, or as the engine of dev-flow step 1 (invoked by the new-feature command).
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

## Overview-spec ingestion

If the arguments reference an overview spec (`docs/features/specs/YYYY-MM-DD-<feat-name>-overview.md`, written by a decomposed roadmap's first run) and it exists, read it **before** anything else. The named run's entry is the established brief — its problem, scope, and deferred checklist are settled; don't re-derive them. Later-run entries are context, not commitments. Record the path in the state file's References (the `Overview:` line, in a dev-flow run). The interview trims to confirmation: restate the run's entry as read and ask only "did I read this right?" plus anything genuinely open.

If the path doesn't exist, say so and proceed as a normal fresh start.

## Explore before asking

Facts are your job, never your human partner's. Before asking design questions, check the current project state: files, docs, recent commits. Anything you could look up yourself, look up — bring findings to the dialogue, don't ask the user for them. Where existing code has problems that affect the work (a file grown too large, unclear boundaries), include targeted improvements as part of the design — but no unrelated refactoring.

## The design tree

Map the design as a **tree**: every decision branches into the decisions that hang off it. Work the tree **one question per message**.

The **frontier** is every decision whose prerequisites are already settled — the questions you can ask *now* without guessing at answers you haven't heard. Track the frontier internally: compute it before each question, and recompute it after each answer (settled decisions push it outward and unblock the decisions that hung off them). A question whose prerequisites aren't settled belongs *later* — never ask it now.

Ask one frontier question per message, then stop and wait for the answer:

```
❓ **<question>**

- **<option A>** — <one line>
- **<option B>** — <one line>
- **<option C>** — <one line>

➡️ <your recommendation — one short line, or only when asked>
```

Max 2-3 options per question, one line each — no long per-option explanations. Give your recommendation either as one short inline line or only when asked; never a paragraph of advocacy. Some questions have no options — an open question is fine too.

The session is done when the frontier is empty: every branch visited, nothing left silently assumed.

**Flag decomposition early.** If the request spans multiple independent subsystems, flag it *before* spending questions on details: help decompose into sub-projects (what are the pieces, how do they relate, what order), then brainstorm the first sub-project through the normal flow. Each sub-project gets its own spec → plan → implementation cycle. When the decomposition flag fires, also write an **overview spec** to `docs/features/specs/YYYY-MM-DD-<feat-name>-overview.md` recording all runs, their order, their dependencies, and each run's deferred checklist (the pieces deliberately pushed to later runs). Write it only when decomposition fires — never for a plain spike or bounded run.

**Re-anchor on drift.** A question can be locally reasonable and still drift off the brief. **Before each frontier question**, run one internal check: does answering this move the design within the problem and scope stated in the interview? If you notice the current thread has drifted (interesting, but outside the stated problem or scope), stop and say so out loud — do not silently change direction: (1) name the drift, (2) restate the problem in one line to re-anchor, (3) make the capture-or-drop decision on the drifted thread out loud: if it is worth keeping, propose filing it as a GitHub issue (a new one, or folded into a related existing issue) and create it only after the user confirms — issue creation is outward-facing and never fires silently mid-dialogue; if it is not worth keeping, say you are consciously dropping it. Never silently discard a drifted thread.

## Approaches

Once you understand what you're building, propose **2-3 approaches** with trade-offs. Present them conversationally, lead with your recommendation and reasoning. **YAGNI ruthlessly** — remove unnecessary features from every approach before presenting.

## Presenting the design

Present the design in sections scaled to their complexity — a few sentences if straightforward, a couple of paragraphs if nuanced. Ask after each section whether it looks right so far. Cover: architecture, components, data flow, error handling, testing.

**Design for isolation:** break the system into units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently. For each unit you should be able to answer: what does it do, how do you use it, what does it depend on? If you can't change the internals without breaking consumers, the boundaries need work.

**Viability pass — pressure-test before approval.** Before asking your human partner to approve the design, validate that it is actually good to develop. On **architectural** paths this is a fresh-eyes check: spawn a fresh adversarial subagent (same pattern as a fresh reviewer — no model pin; the pick is environment-specific), brief it on the design and the problem it serves, and have it red-team the design: **what breaks, what's over-built, what's the better alternative, does it clear its domain's quality bar** (e.g. UI/UX coherence for frontend designs, latency and error-handling for APIs, data integrity for schemas — the bar the design's own domain sets), **is it solving the right problem — is the idea/direction itself correct, or is there a better target?** Present its findings alongside the design. A *fundamental* finding on any of the five — the design has a real flaw, or solves the wrong problem — **blocks**: restart the design section with that finding addressed before approval is requested. *Minor* findings are advisory: present them as noted risks and let the human partner weigh them at approval time. On **bounded** paths, downgrade to a lightweight self-check: include a one-line "why this could fail" in the design presentation. **Spike** paths are unchanged — a spike's terminal state is a reported recommendation.

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