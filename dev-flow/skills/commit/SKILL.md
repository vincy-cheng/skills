---
name: commit
description: Use whenever the user wants to commit staged or current changes ("commit this", "make a commit", "save progress", "commit the work"). Writes a Conventional Commits message from the diff and commits. Can run standalone or as part of dev-flow step 5 (per-task commits during TDD execution). NEVER mentions or attributes any AI model, assistant, or tool in the commit message or any trailer — the commit reads as if the human author wrote it.
---

# Commit

Stage the right files, write a Conventional Commits message from the diff, commit. **No AI attribution, ever.**

## Iron rule — no AI attribution

The message, body, and **all trailers** read as if the human author wrote it:

- **No** `Co-Authored-By: Claude` / `Co-Authored-By: <AI>`.
- **No** `🤖 Generated with ...` / `Generated with Claude Code` / `Generated with [tool]`.
- **No** mention of Claude, Anthropic, the model name, or any AI tool anywhere.
- The only author is the configured git user (`git config user.name` / `user.email`).

Strip any AI attribution another process injected. Don't add trailers unless the user asks for one by name.

## When this runs

1. **Standalone** — "commit this" outside any workflow. Commit the current changes.
2. **dev-flow step 5** — per-task commits after each task's test goes green. The commit covers **one task** only; don't stage files outside it.

## Workflow

1. **See what changed.**
   ```bash
   git status --porcelain
   git diff --stat
   ```
2. **Stage explicitly** (`git add <specific files>`) — never `git add -A` / `git add .`. In dev-flow step 5, stage the current task's files (its `**Files:**` block names them). If scope is ambiguous, ask the user before staging.
3. **Draft the message** from the staged diff (see Message format). Confirm with the user, or commit directly if they already said "commit" with clear scope.
4. **Commit.**
   ```bash
   git commit -m "<subject>" -m "<optional body>"
   ```
   Use a heredoc for multi-paragraph bodies. Don't pass `--no-verify`; let hooks run.
5. **Report** the short hash and subject. In dev-flow step 5, the workflow (not this skill) also flips the state file's task checkbox and bumps **Updated**.

## Message format — Conventional Commits

```
<type>(<optional scope>): <imperative subject>

<optional body — bullets, one per change or reason>
```

- **Subject**: imperative, lowercase first letter, no trailing period, ≤72 chars. Describes *what this commit does*, not the process that produced it.
- **Type**: `feat` (capability), `fix` (bug), `refactor`, `test`, `docs`, `chore`, `perf`, `build`, `ci`, `style`, `revert`. dev-flow fix → `fix`; feature → `feat`.
- **Scope** (optional): module/component, e.g. `feat(history): ...`. Infer from files; omit if unclear rather than invent.
- **Body** (optional): wrap at ~72. **Use bullet points** (`-`), one per change or per reason — preferred over prose. Explain *why*; the diff shows *what*. Skip if the subject says it all; a one-line commit is fine:
  ```
  feat(history): group sum-up totals by payment method

  - group rows by payment method before summing
  - add `PaymentMethodTotals` view model + tests
  - fixes duplicate totals when a payment spans two methods
  ```

### Inferring type from the diff

- Test file alone → `test(scope): ...`.
- Source + its test together → `feat`/`fix` (the capability/fix is the point; the test is part of it).
- Only docs/README → `docs`.

## What not to do

- **No AI attribution** in message, body, or trailers.
- **No `git add -A` / `git add .`** — stage explicitly.
- **No `--no-verify`** unless a hook is known-broken and the user asks.
- **No process narration** ("wrote tests then implemented") — describe the change ("add retry with backoff to upload client").
- **No staging `docs/features/`** — if it appears untracked, gitignore drifted; fix the ignore, don't commit the file.
- **No empty commits** unless the user asks.
- **No pushing** — this skill commits only. Push is dev-flow step 9, separately gated.