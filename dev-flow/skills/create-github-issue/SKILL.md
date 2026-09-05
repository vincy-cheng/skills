---
name: create-github-issue
description: Use whenever the user wants to create, open, file, or draft a GitHub issue — whether they say "create an issue for X", "file a bug", "open an issue", "track this", "log this as something to do", or describe a feature/bug they want tracked. Also use when turning a conversation, bug report, or feature idea into a tracked GitHub issue. This is step 4 of the dev-flow workflow (brainstorm → spec → plan → **create issue** → execute → PR → merge), so it also triggers at the end of planning once a plan doc exists and the work needs a tracking issue. Triggers on any mention of creating/filing/opening an issue, even without the word "issue" explicitly. Works in any repo that uses the `gh` CLI.
---

# Create a GitHub issue

This is **step 4** of the dev-flow workflow:

1. Brainstorm (`superpowers:brainstorming`)
2. Spec — local design doc only (`docs/features/specs/`)
3. Plan (`docs/features/plans/`, `superpowers:writing-plans`)
4. **Create issue** ← this skill
5. Execute tasks (TDD: test, implement, fix if failing)
6. Open PR (branch flow `main` → `dev` → `feature/<issue-number>-<name>` or `fix/<issue-number>-<name>`)
7. Merge (manual, by the human)

By the time this skill runs, steps 1–3 may have already produced a spec doc and/or a plan doc. This skill turns that material into a tracked GitHub issue and publishes it with `gh`. A consistent issue shape makes it easy to triage, link the spec/plan, and spin up the `feature/` (or `fix/`) branch for step 6.

## Gate check (dev-flow step 4)

This skill is part of the dev-flow plugin's `/new-feature` workflow, which uses a state file (`docs/features/.feature-states/<feat-name>.state.md`) as a hard gate between steps. **On entry, verify the state file's Goal status is `planning`; set it to `issue` before drafting.** If the status is not `planning`, stop — a step has been skipped — and tell the user which step the state file says to run. If no state file exists (this skill invoked standalone, outside dev-flow), skip the gate and proceed normally.

## Why a fixed structure

A reader (human or AFK agent) should be able to understand the *what*, the *boundaries*, the *done-state*, and the *where-to-look-next* from the issue body alone, without the conversation that produced it. That is exactly what the four required sections — Summary, Scope, Expected behavior, References — guarantee. The suggested sections make that contract tighter.

## Workflow

1. **Pull context from steps 1–3.** Before drafting, check for the artifacts the earlier workflow steps produced:
   - `docs/features/specs/` — the design doc. If present, mine it for Summary, Scope, and Expected behavior.
   - `docs/features/plans/` — the implementation plan. If present, mine its task breakdown for the **Tasks** section.
   If those docs exist, you should mostly be *translating* them into the issue, not re-deriving the content — that's the point of having done steps 1–3 first. If they don't exist (e.g., a small bug filed straight from a conversation), gather intent the usual way: extract the substance, and if anything material is missing (which component, what's wrong vs. what's expected, relevant files), ask — briefly, in one combined turn. Don't pad with guesses; a wrong guess in a published issue misleads a future reader. (Mine the substance INTO the issue body — the issue must be self-contained since these docs are gitignored and invisible on GitHub; never link them as references.)
2. **Draft the body** using the template below. Fill every required section. Use the suggested sections when they add signal (guidance in the template).
3. **Show the draft to the user** — render the title + body in the conversation. Ask for confirmation before publishing. The user picks labels at this point (see Labels below).
4. **Publish.** Run `gh issue create` with a heredoc body. Capture the returned URL and issue number.
5. **Offer follow-ups.** Offer to create a working branch for the issue (see Branches below) if the repo's workflow calls for one. Do so only if the user accepts.

## The template

```markdown
## Summary
One paragraph: what is this issue, in plain language. The problem or opportunity. A reader who knows nothing about the conversation should understand the *why* after this.

## Scope
The specific changes / surface area this issue covers. Be concrete: components, files, modules, endpoints, or behaviors in play. Bullet list is fine. This is the *what we're touching*, and it bounds the work — anything not listed here belongs in Out of scope (suggested) or a separate issue.

## Expected behavior
The observable end state once the work is done — what the user sees or what the system does, described narratively. For a bug, this is the *correct* behavior contrasting the current broken behavior. For a feature, this is the intended UX/behavior. Keep it behavioral, not implementation.

## References
Links to prior context: related issues (`#NN`), relevant commits, or external links. **Do NOT link the spec/plan docs** (`docs/features/specs/`, `docs/features/plans/`) — the entire `docs/features/` folder is gitignored, so those files exist only on the author's machine; a GitHub reader (human or agent) following the link finds nothing. The spec's substance belongs in the issue body itself (that's why you mine it into Summary/Scope/Expected behavior), not behind a dead local path. If no references exist yet, write `_(none yet — add links as they're created)_` so the section is an obvious placeholder to fill in later.
```

### Suggested sections (use when they add signal)

These are optional but often pull their weight. Add them as top-level `##` sections, slotted in this order:

- **## Out of scope** — right after Scope. Explicit non-goals. Pairing Scope with Out of scope is the single best defense against scope creep on a published issue, because a future reader can't tell what you *meant* to exclude. Name the things adjacent to this work that someone might reasonably tack on — and say they go in a separate issue.
- **## Acceptance criteria** — right after Expected behavior. A checklist (`- [ ]`) of concrete, checkable outcomes. Expected behavior is the narrative; acceptance criteria are the *tests*. If you can't write a checkable item for some part, that part is under-specified — go back and tighten it. This is what a reviewer or agent uses to know "done".
- **## Tasks** — after References. A `- [ ]` breakdown of implementation steps (e.g. "model + data layer + tests", "provider/state wiring", "UI + widget test", "migration + migration test"). Only add this if the decomposition is real — a wishful task list is worse than none.

When in doubt, prefer a tight issue over a complete-looking one. A short, honest issue is easier to triage than a long, padded one.

## Labels

Let the user pick labels per issue — do not assume. After showing the draft, fetch the repo's current labels so the menu reflects what actually exists (hardcoding labels goes stale as the repo evolves):

```bash
gh label list --json name,description --jq '.[] | "\(.name)\t\(.description)"'
```

Then offer the relevant ones and let the user choose. If the user declines, create the issue with no labels — triage can happen later.

## Publishing

Publish with a heredoc so the body renders as Markdown:

```bash
gh issue create --title "<title>" --body "$(cat <<'EOF'
<full body markdown here>
EOF
)" --label "<label1>" --label "<label2>"
```

- Title: imperative, concise, no trailing period. If the repo uses Conventional-Commits-style titles (e.g. `feat(history): group sum-up totals by payment method`), match that house style; otherwise a plain descriptive title is fine. Infer house style from recent issues if unsure.
- Omit `--label` entirely if no labels were chosen.
- After publishing, capture the issue number from the output — the branch step needs it.

## Branches

This skill is step 4 of a workflow whose step 6 is a PR on the `main` → `dev` → `feature/<issue-number>-<name>` (or `fix/<issue-number>-<name>`) flow. So the branch for the *next* step (execute) should come off `dev`, not `main`. After the issue is published, offer:

> "Issue #NN is created. Want me to create a `feature/NN-<name>` (or `fix/NN-<name>`) branch off `dev` and switch to it?"

Use the `fix/` prefix when the state file's **Kind** is `fix`, and `feature/` otherwise. If accepted:

```bash
git checkout dev && git pull --ff-only origin dev && git checkout -b feature/NN-<name>
# or, for a fix:
git checkout dev && git pull --ff-only origin dev && git checkout -b fix/NN-<name>
```

The `pull --ff-only` keeps `dev` current. If the pull is rejected (local `dev` has diverged), surface that to the user rather than force-anything. Do not commit anything yet — the branch is just scaffolding so step 5 (execute) can start. In repos without a `dev` integration branch, fall back to branching off the default base.

## Dev-flow state file

The dev-flow workflow maintains a gitignored state file (`docs/features/.feature-states/<feat-name>.state.md`) that tracks progress so any session can resume. The entire `docs/features/` folder is gitignored. When you run as part of that workflow and a state file exists, update it as part of step 4:

- Set **Goal status** to `issue` while drafting, and leave it for step 5 to advance.
- Record the issue number in References → `Issue: #NN` (replace the `_(pending)_` placeholder).
- If the user accepts the branch, set the state file's **Base branch** to `feature/NN-<name>` or `fix/NN-<name>` (the working branch for steps 5–6); **Target branch** stays `dev` (the PR destination).
- Bump the **Updated** timestamp on every write.

You don't create the state file here — step 1 does. Only touch it if it already exists, and only the fields above.

## What not to do

- Don't publish before the user confirms the draft. A published issue is outward-facing and visible to collaborators.
- Don't invent references. If there's no design/plan doc yet, say so in References rather than linking to a file that doesn't exist.
- Don't add the suggested sections reflexively. Out of scope and acceptance criteria are valuable *when they carry real information*; a section that says "N/A" is noise that trains the reader to skip sections.
- Don't hardcode the label list — fetch it. Repos drift.