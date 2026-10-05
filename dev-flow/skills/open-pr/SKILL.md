---
name: open-pr
description: Use to open a pull request for a feat or fix branch — dev-flow step 9 (after doc-fix, before the manual merge). Pushes, drafts the PR body (issue link, spec/plan summary, closing keyword), shows it for confirmation, opens with `gh pr create` targeting the state file's Target branch (`dev` by default), links the issue via `Closes #N`, syncs the issue body (flips satisfied acceptance-criteria checkboxes, adds `PR: #NN` to References), and records the PR number in the state file. Also runs standalone for any branch ("open a PR for this branch", "create the PR"). Never merges — step 10 is manual. No AI attribution in the PR body.
---

# Open PR

Step 9 of dev-flow. The branch's work is done, tested (step 6), reviewed (step 7), and doc-fixed (step 8) — this skill ships it as a reviewable PR. It never merges — step 10 is the human's manual merge.

## Gate (dev-flow, step 9)

If running inside dev-flow (state file at `docs/features/.feature-states/<feat-name>.state.md` exists), verify **Goal status** is `doc-fix`. **The orchestrator sets `pr-review`** — the skill checks the incoming status; the orchestrator writes the advance. Wrong status → stop, tell the user which step to run. No state file (standalone) → see *Standalone mode*.

## What you need

- The **base branch** — the state file's **Target branch** (`dev` by default, or `.dev-flow/config.json`'s `dev_branch`; the PR target; never the default branch in the multi-branch flow).
- The **branch name** — `feat/<n>-<name>` / `fix/<n>-<name>`.
- The **issue number** — from the state file's References.
- The state file's **References** — spec/plan paths are local-only (`docs/features/` is gitignored); their substance is summarized into the PR body, never linked.

## Draft the PR body

Mine the issue body and the branch's commit messages — the PR body summarizes what and why, translating the issue's structure, not re-deriving it:

```markdown
## Summary

<One paragraph: the problem and the change. Link the issue: "Resolves the workflow gaps in #11.">

## Changes

<Concrete bullets: what changed, file-by-file or concern-by-concern.>

Closes #11
```

**Closing-keyword rules:**
- **`Closes #N`** when the PR fully resolves the issue.
- Partial resolution → plain reference (`Part of #N`) and say so in the Summary.

**No AI attribution.** The body reads as if the human author wrote it: no model names, no "generated with", no AI attribution trailers. Same policy as the `commit` and `create-github-issue` skills.

## Show, confirm, open

Show the user the drafted title + body. On confirmation:

1. **Commit guard first** — `git status --porcelain docs/features/` must be empty. Not empty → stop and fix before pushing.
2. Push and open:

```bash
git push -u origin HEAD
gh pr create --base <target-branch> --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

`<target-branch>` is the state file's **Target branch** (`dev` by default, else `.dev-flow/config.json`'s `dev_branch`; standalone mode: confirmed with the user). Capture the PR URL and number.

## Link the issue (sidebar)

A `Closes #N` keyword in the body creates the issue↔PR sidebar cross-reference the moment the PR opens — no extra API call. Because the PR targets the state file's Target branch (not the default branch), GitHub won't auto-close the issue on merge — if it should close on this merge, close it explicitly in step 10 or 11 (`gh issue close <N>`).

## Sync the issue body

The work is done and reviewed, so the issue reflects that:

1. Fetch: `gh issue view <N> --json body -q .body`
2. **Flip satisfied acceptance-criteria checkboxes** `[ ]` → `[x]`. Leave unchecked any criterion the PR didn't satisfy. No checklist → skip the flips.
3. **Add `- PR: #NN` to the References block** (create the block if absent).
4. Write back: `gh issue edit <N> --body ...`

This is the durable text record inside the issue; it complements (not duplicates) the sidebar cross-reference.

## Record and hand back

Record `PR: #NN` in the state file's **References** (replace `_(pending)_`); bump **Updated**; hand back to `/new-feature` for step 10 (manual merge — the user merges, this skill never does).

## Standalone mode (outside dev-flow)

No state file → open a PR for the current branch against its base (ask which base if unclear). Still draft and show the body for confirmation first. No issue link or issue-body sync unless the user points to an issue.

## What not to do

- **Don't merge** — step 10 is manual, by the human. This skill opens PRs; it never merges.
- **Don't open before the user confirms the body** — a PR is outward-facing.
- **Don't target the default branch in the multi-branch flow** — PRs target the state file's Target branch (branch flow: default → configured dev branch → `feat/<n>-<name>`).
- **Don't commit `docs/features/`** — gitignored; the commit guard checks before pushing.
- **No AI attribution** in the PR body — no model names, no "generated with", no trailers.
- **Don't auto-close the issue** — the PR targets the state file's Target branch (not the default branch), so closing keywords don't auto-close on merge; close explicitly in step 10 or 11 if intended.