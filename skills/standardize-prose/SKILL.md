---
name: standardize-prose
description: Standardize the prose language of a dev-flow spec or plan for human readers — a guided cleanup pass adapted from ASD-STE100 Simplified Technical English. Use when the user says "standardize this spec/plan", "clean up the language in this doc", "fix the terminology drift", or names a doc to polish. Standalone — never part of the dev-flow step pipeline. Rewrites prose only; never touches code blocks, Mermaid, tables, file paths, identifiers, Risk lines, checkbox lines, or the frozen modals shall/must/will/may.
---

# Standardize terms

A guided cleanup pass that rewrites a design doc's prose into controlled,
human-friendly technical English. Language only — the doc's structure,
content, and technical meaning never change.

## Iron rule

NO EDIT BEFORE EXPLICIT CONFIRMATION. The scan produces proposals; the file
changes only after the user approves the preview. No "small fixes first".

## Attribution

Rules distilled in spirit from ASD-STE100 Simplified Technical English
(Issue 9), owned by ASD — Aerospace, Security and Defence Industries
Association of Europe (EU registered trademark). This skill paraphrases the
standard's writing-rule principles for software docs; no STE text, dictionary
entries, or examples are reproduced. Official standard:
https://www.asd-ste100.org/assets/files/ASD-STE100_ISSUE9.pdf

## Workflow

1. **Trigger** — a doc path argument, or the user's request names the doc
   ("this spec", "that plan"). No doc named → ask which file.
2. **Entry gates — refuse and stop, with the reason:**
   - File missing → name it and stop.
   - **Active-run gate** — read `docs/features/.feature-states/*.state.md`.
     If the doc belongs to a run whose Goal status is not `done` or
     `merged`, refuse: the plan's task lines are verbatim-copied into the
     state file, acceptance criteria mirror into the issue body, and the
     test/review steps judge against the docs' current text — rewriting
     mid-run desyncs three artifacts. Offer to re-run after the run closes.
   - Doc > 1,000 lines → suggest running it section by section.
3. **Load** `references/writing-rules.md` and `references/software-terms.md`.
4. **Backup** — copy the doc verbatim to `<filename>.bak` next to it before
   any edit. This is the only revert path (the doc is gitignored); a skipped
   backup is a stopped skill.
5. **Scan and rewrite prose** — group findings by rule category, collect
   (before → after) pairs. Skip everything in the never-touch list below.
6. **Guided preview** — per category, 1-2 representative pairs each, cap
   ~10 pairs total; remaining same-pattern fixes collapse to one line
   ("38 more: same passive→active fix"). **Exception:** passive→active
   rewrites never collapse — every pair is shown individually, because an
   invented agent is the costliest error this pass can make.
7. **Apply** — user picks: apply all / apply one category / cancel.
   Apply with one edit per pair. An edit that fails (text moved since the
   scan) → re-read that section, re-derive the pair, re-apply — never skip
   silently.
8. **Report** — per-category counts, the backup path, and the skipped ratio
   when the doc is code-heavy ("62 prose sentences scanned, 14 rewritten;
   code blocks and tables untouched").

## Never-touch list

- **Blocks:** code fences, Mermaid diagrams, tables, YAML frontmatter.
- **Lines:** `Risk:` lines, checkbox lines (`- [ ]` / `- [x]`),
  `**Files:**` blocks, file paths, code identifiers — style rewrites never
  touch them (plan task lines are verbatim-copied into the state file).
- **Frozen modals:** shall, must, will, may — never rewritten, never swapped
  (*must* binds, *will* predicts, *may* permits).
- **Agent constraint:** an active-voice rewrite names only an agent present
  verbatim in the original sentence. A deliberate passive (unknown or
  irrelevant agent) stays passive.
- **Prose nouns only:** the term list standardizes prose nouns — code
  identifiers, API paths, and file names are never rewritten to match it.

## Outcomes

- **Findings applied** → report counts + backup path; remind the user the
  `.bak` file can be diffed or deleted.
- **No violations** → say the doc already complies — an honest no-op pass,
  no edits, no invented findings.
- **User cancels** → delete the `.bak` file? Ask; default keep.

## What this is not

- Not a re-review and not a content editor: structure, requirements, and
  risks in the doc stay exactly as written.
- Not wired into the dev-flow pipeline: legacy docs and missed drift only,
  invoked by a human on purpose.
- Not a rewriter of meaning: if a sentence is ambiguous because the *design*
  is ambiguous, flag it — do not pick a reading and rewrite silently.