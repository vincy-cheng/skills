---
name: commit
description: Use whenever the user wants to commit staged or current changes ("commit this", "make a commit", "save progress", "commit the work"). Writes a Conventional Commits message from the diff and commits. Can run standalone or as part of dev-flow step 5 (per-task commits during TDD execution). NEVER mentions or attributes any AI model, assistant, or tool in the commit message, co-author trailer, or any trailer — the commit reads as if the human author wrote it.
---

# Commit

Stage the right files, write a Conventional Commits message from the diff, and commit. **No AI attribution, ever.**

## Iron rule — no AI attribution

The commit message, body, and **all trailers** must read as if the human author wrote it. Concretely:

- **No** `Co-Authored-By: Claude` or any `Co-Authored-By: <AI>` trailer.
- **No** `🤖 Generated with ...` / `Generated with Claude Code` / `Generated with [tool]` line.
- **No** mention of Claude, Anthropic, the model name, or any AI tool/assistant anywhere in the message.
- The only author is the git user already configured (`git config user.name` / `user.email`).

If some other process or template injected AI attribution into a draft message, strip it before committing. Do not add trailers unless the user explicitly asks for one by name.

## When this runs

Two modes:

1. **Standalone** — the user says "commit this" / "make a commit" outside any workflow. Commit the current changes.
2. **dev-flow step 5** — per-task commits during TDD execution. The `/new-feature` workflow commits after each task's test goes green. In this mode, the commit covers **one task** (the files that task touched), not the whole feature. Do not stage files outside that task.

## Workflow

1. **See what changed.**
   ```bash
   git status --porcelain
   git diff --stat
   ```
   If dev-flow step 5: stage only the **current task's** source files explicitly (`git add <specific files>`). Never `git add -A` / `git add .` — `docs/features/` (spec/plan/state) is gitignored but gitignore can drift, and staging explicitly is the guard against leaking it.
2. **If nothing is staged, stage the intended files.** Ask the user if scope is ambiguous (e.g. untracked files that may or may not belong). For a dev-flow task, the task's `**Files:**` block names exactly what to stage.
3. **Draft the message** from the staged diff (see Message format). Show it to the user for confirmation — unless the user already said "commit" with clear scope, in which case commit directly. A published commit is outward-facing once pushed; before push, a quick confirm costs little.
4. **Commit.**
   ```bash
   git commit -m "<subject>" -m "<optional body>"
   ```
   Or a heredoc for multi-paragraph bodies. Do not pass `--no-verify`; let hooks run.
5. **Report** the short hash and subject back. If dev-flow step 5, also update the state file's task checkbox and **Updated** timestamp (the workflow's rule, not this skill's — the workflow drives that).

## Message format — Conventional Commits

```
<type>(<optional scope>): <imperative subject>

<optional body — what and why, not how>
```

- **Subject**: imperative mood, lowercase first letter, no trailing period, ≤72 chars. Describes *what this commit does*, not what was done to produce it.
- **Type**: `feat` (new capability), `fix` (bug fix), `refactor`, `test`, `docs`, `chore`, `perf`, `build`, `ci`, `style`, `revert`. For a dev-flow fix workflow, prefer `fix`; for a feature workflow, `feat`.
- **Scope** (optional): the module/component touched, e.g. `feat(history): ...`. Infer from the files; omit if unclear rather than invent.
- **Body** (optional): wrap at ~72. **Use bullet points** (`-`), one per change or per reason — preferred over prose paragraphs. Each bullet = one concrete change or one "why". Explain *why* the change exists; the diff already shows *what*. Skip the body if the subject already says everything; a one-line commit is fine. Example:
  ```
  feat(history): group sum-up totals by payment method

  - group rows by payment method before summing
  - add `PaymentMethodTotals` view model + tests
  - fixes duplicate totals when a payment spans two methods
  ```

### Inferring type and scope from the diff

- A new test file alone → `test(scope): ...`.
- Source + its test together → `feat`/`fix` (the capability/fix is the point; the test is part of it).
- Only docs/README → `docs`.
- `docs/features/` files are gitignored and **never** committed — if they appear in `git status`, do not stage them; surface it (the dev-flow preflight should have gitignored them).

## What not to do

- **No AI attribution** in message, body, or trailers (the iron rule above).
- **No `git add -A` / `git add .`** — stage explicitly.
- **No `--no-verify`** unless a hook is known-broken and the user asks.
- **No commit message that describes the *process*** ("wrote tests then implemented") — describe the *change* ("add retry with backoff to upload client").
- **No staging `docs/features/`** — if it shows as untracked, it's a gitignore drift; fix the ignore, don't commit the file.
- **No empty commits** unless the user explicitly asks.
- **No pushing** — this skill commits only. Push is a separate, user-gated action (dev-flow step 6).