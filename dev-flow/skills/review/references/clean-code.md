# Clean-code checklist (review section 4)

The full maintainability & clean-code pass for the review's section 4 — read this file before running section 4, in place of the inline checklist.

Read the changed code in place (open the files, not just the diff hunks) — what does the next maintainer inherit?

- **Structure** — one thing per module/function; new code follows existing patterns?
- **Coupling** — layering violations, hidden dependencies, leaked internals.
- **Naming** — names that say what things do, not just locally true ones.
- **Complexity** — deep nesting, long functions, branching a simpler shape would kill.
- **Duplication** — logic copied from elsewhere in the codebase (diff-only reading misses this).

Then a **clean-code pass** over the changed code (distilled from the classic clean-code checklist — wojteklu's gist, the r/cleancode guide):

- **Names** — descriptive and unambiguous, pronounceable, searchable; magic numbers → named constants; no type-prefix encodings; meaningful distinctions (not `data2`).
- **Functions** — small, do one thing, few arguments, no side effects, no flag arguments (a boolean param selecting behavior → split into independent methods); does only what its name promises — no surprising behavior (least astonishment).
- **Error handling** — managed errors over crash paths (try/catch where the failure is expected, resources freed in `finally` or equivalent); a swallow-everything catch is a bug finding (section 3), but a new unhandled crash path belongs here.
- **Conditionals** — no negative conditionals where a positive one reads cleaner; boundary conditions encapsulated in one place; no methods whose correctness depends on another method in the same class having run.
- **Comments** — code explains itself first; comments carry intent/clarification/warnings only, never redundancy, obvious noise, closing-brace tags, or commented-out code (commented-out code is a leftover — see section 3).
- **Structure** — variables declared close to usage; dependent/similar functions close; related code vertically dense; separate concepts separated vertically.
- **Code smells** — rigidity (small change cascades), fragility (one change breaks many places), immobility (can't reuse), needless complexity, needless repetition, opacity (hard to understand).
- **KISS** — the simplest shape that works; simpler is always better (the needless-complexity smell is its detection point).
- **DRY** — every piece of knowledge has one authoritative representation (beyond copied code blocks — the duplication check extends to knowledge-level repetition: the same fact/rule stated in two places).
- **Boy-scout** — the diff leaves the touched code cleaner, not worse; incidental tidy-ups are noted, not demanded.

Consistency beats purity — match the file's existing conventions over textbook clean-code (legacy style stays legacy unless the task touches it); a DRY extraction that adds more complexity than it removes is itself a finding.

Report findings with file:line and a concrete suggested shape ("extract X into Y") — suggest, don't fix. Can be blue, yellow, or red; severity is the reviewer's judgment. Clean-code findings are usually blue or yellow — red only when the shape would actively break under the next change.