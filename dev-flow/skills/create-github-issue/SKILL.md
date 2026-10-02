---
name: create-github-issue
description: Use whenever the user wants to create, open, file, or draft a GitHub issue — "create an issue for X", "file a bug", "open an issue", "track this", "log this", or describes a feature/bug to track. Also when turning a conversation, bug report, or feature idea into a tracked issue. This is step 4 of the dev-flow workflow (brainstorm → spec → plan → **create issue** → execute → PR → merge), so it also triggers at the end of planning once a plan doc exists. Triggers on any mention of creating/filing/opening an issue, even without the word "issue". Works in any repo with the `gh` CLI.
---

# Create a GitHub issue

**Step 4 of dev-flow.** Turns the spec + plan into a tracked GitHub issue, published with `gh`. Steps 1–3 may have produced `docs/features/specs/` and `docs/features/plans/`; this skill translates that material into a self-contained issue. Branch for step 5 is `feat/<n>-<name>` (or `fix/<n>-<name>` off `dev`).

## Gate check

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), **verify Goal status is `planning` and set it to `issue` before drafting.** If not `planning`, stop — a step was skipped — and tell the user which step to run. No state file (invoked standalone) → skip the gate, proceed.

## Why a fixed structure

A reader (human or agent) should understand the *what*, *boundaries*, *done-state*, and *where-to-look-next* from the issue body alone. The four required sections — Summary, Scope, Expected behavior, References — guarantee that; the suggested sections tighten it.

## Workflow

1. **Pull context from steps 1–3.** Mine `docs/features/specs/` for Summary/Scope/Expected behavior, and `docs/features/plans/` for the Tasks section. Translate, don't re-derive — that's the point of doing steps 1–3 first. If the docs don't exist (e.g. a small bug filed straight from a conversation), gather intent and ask — briefly, in one turn — if anything material is missing (component, wrong vs. expected, relevant files). Don't pad with guesses. Mine the substance **into the issue body** — it must be self-contained since `docs/features/` is gitignored and invisible on GitHub. Never link those docs as references.
2. **Draft the body** with the template below. Fill every required section; add suggested sections when they add signal.
3. **Show the draft** (title + body) and ask for confirmation. The user picks labels here.
4. **Publish** with `gh issue create` (heredoc). Capture the URL and issue number.

**One-issue-ahead.** When operating inside a dev-flow run whose state-file References carry an Overview path, open an issue only for the **imminent** run — later runs stay in the overview spec (pre-opened issues go stale when direction shifts mid-way). Standalone use (no state file, no Overview) is unaffected — never refuse a plain issue request.
5. **Offer a branch** (see Branches) if the repo's workflow calls for one. Only if the user accepts.

## The template

```markdown
## Summary
One paragraph, plain language: the problem or opportunity. A reader who knows nothing of the conversation understands the *why*.

## Scope
The specific changes / surface area. Be concrete: components, files, modules, endpoints, behaviors. Bullet list is fine. Bounds the work — anything not listed belongs in Out of scope or a separate issue.

## Expected behavior
The observable end state once done — what the user sees or the system does. For a bug, the *correct* behavior contrasting the broken one. Behavioral, not implementation.

## References
Prior context: related issues (`#NN`), relevant commits, external links. **Do NOT link `docs/features/specs/` or `docs/features/plans/`** — that folder is gitignored and exists only on the author's machine; a GitHub reader finds nothing. An overview spec lives there too — same dead-link rule. The spec's substance belongs in the body, not behind a dead local path; when the run is part of a roadmap, describe its position in prose instead ("run N of M in the local overview spec"). If none yet, write `_(none yet — add links as they're created)_`. **Exception — idea folders link fine:** if the state file's References record an idea folder (`ideas/[<project>/]<slug>/`, committed and visible on GitHub in the same repo), link it — it's the durable research/cost record behind the issue.
```

### Suggested sections (use when they add signal)

Add as top-level `##` sections, in this order:

- **## Out of scope** — after Scope. Explicit non-goals. The best defense against scope creep: a future reader can't tell what you *meant* to exclude. Name adjacent things someone might tack on, and say they go in a separate issue.
- **## Acceptance criteria** — after Expected behavior. A `- [ ]` checklist of concrete, checkable outcomes. Expected behavior is the narrative; this is the *tests*. If you can't write a checkable item for part of it, that part is under-specified — tighten it.
- **## Tasks** — after References. A `- [ ]` implementation breakdown. Only if the decomposition is real — a wishful list is worse than none.

When in doubt, prefer a tight issue over a complete-looking one. Short and honest triages better than long and padded.

**No AI attribution.** The issue title and body read as if the human author wrote them: no model names, no "generated with", no AI attribution trailers. Same policy as the `commit` skill.

## Labels

Let the user pick — don't assume. After showing the draft, fetch the repo's current labels (hardcoding goes stale):

```bash
gh label list --json name,description --jq '.[] | "\(.name)\t\(.description)"'
```

Offer the relevant ones. If the user declines, create with no labels — triage later.

## Publishing

```bash
gh issue create --title "<title>" --body "$(cat <<'EOF'
<full body markdown here>
EOF
)" --label "<label1>" --label "<label2>"
```

- Title: imperative, concise, no trailing period. Match the repo's house style (Conventional-Commits-style if recent issues use it, e.g. `feat(history): ...`); infer from recent issues.
- Omit `--label` if none chosen.
- Capture the issue number — the branch step needs it.

## Branches

Step 9's PR is on `main` → `dev` → `feat/<n>-<name>` (or `fix/<n>-<name>`). So step 5's branch comes off `dev`, not `main`. Use `fix/` when the state file's **Kind** is `fix`, else `feat/`. If `dev` doesn't exist, ask before doing anything: create it off the default branch (`git checkout -b dev && git push -u origin dev`) and branch off it, or branch off the default branch directly. Update the state file's **Base branch** to match. After publishing, offer:

> "Issue #NN created. Want me to create a `feat/NN-<name>` (or `fix/NN-<name>`) branch off `dev` and switch to it?"

If accepted:
```bash
git checkout dev && git pull --ff-only origin dev && git checkout -b feat/NN-<name>
# or, for a fix:
git checkout dev && git pull --ff-only origin dev && git checkout -b fix/NN-<name>
```

`pull --ff-only` keeps `dev` current. If rejected (local `dev` diverged), surface it — don't force. Don't commit anything; the branch is just scaffolding for step 5.

## State file (dev-flow only)

If a state file exists, update it as part of step 4:
- Set **Goal status** to `issue`; leave it for step 5 to advance.
- Record `Issue: #NN` in References (replace `_(pending)_`).
- If the user accepts the branch, set **Base branch** to `feat/NN-<name>` or `fix/NN-<name>`; **Target branch** stays `dev`.
- Bump **Updated**.

You don't create the state file (step 1 does). Touch it only if it exists, and only the fields above.

## What not to do

- Don't publish before the user confirms — a published issue is outward-facing.
- Don't invent references; if no spec/plan exists, say so rather than linking a dead path.
- Don't add suggested sections reflexively — a section that says "N/A" is noise that trains readers to skip sections.
- Don't hardcode the label list — fetch it. Repos drift.
- Don't mention or attribute any AI model, assistant, or tool in the issue title or body — it reads as if the human author wrote it (same policy as commit).