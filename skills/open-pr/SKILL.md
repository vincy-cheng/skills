---
name: open-pr
description: Use to open a pull request for a feat or fix branch — dev-flow step 9 after doc-fix. For a new PR, drafts the body and asks for confirmation before opening; for a repair loop, updates the recorded PR and issue instead of creating duplicates. Records PR identity and hands back for Step 10. Also runs standalone for any branch ("open a PR for this branch", "create the PR"). Never merges. No AI attribution in the PR body.
---

# Open PR

Step 9 of dev-flow. The branch's work is tested (step 6), reviewed (step 7), and doc-fixed (step 8) — this skill opens or updates its reviewable PR. It never merges.

## Gate (dev-flow, step 9)

If running inside dev-flow, require the orchestrator's verified `pr-review` entry context before any PR publication. If invoked directly with `doc-fix`, return to `/new-feature` for the orchestrator to verify the incoming status, write `pr-review` and its mirrors, then reinvoke this skill with that verified context; do not publish in the first invocation. The orchestrator alone writes `pr-review`; do not expect `doc-fix` again or write the status a second time. Any other or unverified status → stop and report the required step. No state file (standalone) → see *Standalone mode*.

## What you need

- The **base branch** — the state file's **Target branch** (`dev` by default, or `.dev-flow/config.json`'s `dev_branch`; the PR target; never the default branch in the multi-branch flow).
- The **branch name** — `feat/<n>-<name>` / `fix/<n>-<name>`.
- The **issue number** — from the state file's References.
- The state file's **References** — spec/plan paths are local-only (`docs/features/` is gitignored); their substance is summarized into the PR body, never linked.

For an existing PR, use its recorded number/URL and verify repository, source branch, and target branch. If identity is missing, locate and verify a matching existing PR before any update. Do not guess or open a replacement.

## Existing PR repair loop

Show the proposed update and wait for confirmation, preserving the PR number, URL, and issue link. Then push the authorized local branch update so the existing PR updates; never call `gh pr create` or create another issue. An ambiguous or absent match → stop and ask; do not create a replacement during resume.

## Draft the PR body (new PR only)

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

For a new PR, show the user the drafted title + body and wait for confirmation. The `gh pr create` command is new-PR-only. For an existing PR, use the confirmed update from *Existing PR repair loop* and skip this create flow. The commit guard applies before either push.

1. **Commit guard first** — `git status --porcelain docs/features/` must be empty. Not empty → stop and fix before pushing.
2. For a new PR, push and open:

```bash
git push -u origin HEAD
gh pr create --base <target-branch> --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

`<target-branch>` is the state file's **Target branch** (`dev` by default, else `.dev-flow/config.json`'s `dev_branch`; standalone mode: confirmed with the user). Capture the PR URL and number. For an existing PR, push the confirmed update to the same source branch and verify its PR URL and number remain unchanged. Push only when authorized by the target repository's instructions and applicable user authorization; otherwise stop before pushing, preserve local work, and leave the run pending at `pr-review` for the user's push.

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

Record or confirm the same `PR: #NN` in the state file's **References**; bump **Updated** and the index row; hand back to `/new-feature` to run Step 10. In an orchestrated repair loop, `pr-review` remains current; do not change **Status since** unless the orchestrator changed status.

## Standalone mode (outside dev-flow)

No state file → open a PR for the current branch against its base (ask which base if unclear). Still draft and show the body for confirmation first. No issue link or issue-body sync unless the user points to an issue.

## What not to do

- **Don't merge** — step 10 is manual, by the human. This skill opens PRs; it never merges.
- **Don't open before the user confirms the body** — a PR is outward-facing.
- **Don't target the default branch in the multi-branch flow** — PRs target the state file's Target branch (branch flow: default → configured dev branch → `feat/<n>-<name>`).
- **Don't commit `docs/features/`** — gitignored; the commit guard checks before pushing.
- **No AI attribution** in the PR body (per the `No AI attribution.` body rule above).
- **Don't auto-close the issue** — the PR targets the state file's Target branch (not the default branch), so closing keywords don't auto-close on merge; close explicitly in step 10 or 11 if intended.
