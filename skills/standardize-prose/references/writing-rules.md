# Writing rules for spec and plan prose

> Distilled, paraphrased writing rules for technical prose in design docs.
> Adapted in spirit from ASD-STE100 Simplified Technical English (Issue 9),
> owned by ASD — Aerospace, Security and Defence Industries Association of
> Europe. This file is an original paraphrase for software documentation —
> no STE text, dictionary entries, or examples are reproduced. The official
> standard: https://www.asd-ste100.org/assets/files/ASD-STE100_ISSUE9.pdf

Each rule: what it requires, then a software-doc example where the rule is
easy to get wrong. Rules already familiar (short sentences, active voice)
are stated without examples — the examples live where drift actually happens.

## Language scope

These rules are written for English prose. For non-English docs, the
sentence-grammar rules — voice, tense, sentence length, punctuation — do
not apply; term-pick is the operative mechanism there. Two rules survive
regardless of language: one term per concept, and no vague quantifiers
(write the number or name the thing).

## Words

- **One term per concept.** Pick one name for each thing in the doc and use
  it everywhere. Bad: the overview says "module", the requirements say
  "component", the tasks say "both" for the same unit. Good: one word, one
  concept, from title to acceptance criteria.
- **No vague quantifiers.** "Several retries", "appropriate timeout",
  "sufficient coverage" cannot be tested. Write the number or name the
  thing: "3 retries", "a 30-second timeout", "90% line coverage".
- **Keep technical noun compounds short** (≤ 3 words). Bad:
  "nested reactive cache invalidation pipeline stage". Good: name the piece
  and let the sentence carry the structure: "the invalidation stage of the
  reactive cache pipeline".
- **Do not stack synonyms for style.** Technical writing is not prose
  fiction: calling the same field "the key", "the identifier", and "the ID"
  in three paragraphs reads as three fields.

## Verbs

- **Active voice preferred, with the agent named.** Every active-voice
  rewrite may name only an agent that appears in the original sentence.
  "The config loader merges the files" (loader named) — not "We merge the
  files" (no "we" exists in the doc).
- **Deliberate passives stay passive.** When the sentence's point is that
  the agent is unknown or irrelevant, the passive is correct: "the value is
  discarded" — do not invent a subject.
- **Present tense.** The doc describes how the built system behaves: "the
  server rejects the request", not "the server will be rejecting" or "the
  server would reject".
- **One meaning per verb.** "Return" means one thing in the doc (a function
  returns a value). If deletion is meant, say "delete" — not "return the
  data to the pool".

## Sentences

- **One idea per sentence.** Two requirements in one sentence is two tests
  written wrong. Split them.
- **Keep sentences ≲ 20 words.** Longer only when a list of named items
  makes enumeration clearer than splitting.
- **Keep paragraphs short** — a paragraph that covers three concerns is a
  section missing headings.

## Procedural text (plan tasks and steps)

- **One action per step.** "Create the table and update the loader" is two
  tasks in one checkbox; the executor will forget one.
- **Order steps so a reader can stop anywhere** — each completed step leaves
  the system consistent.

## Descriptive text (spec sections)

- **Describe behavior, not implementation history.** "The cache stores the
  slug for 24 hours" — not "We decided to store the slug and later changed
  it to 24 hours".
- **Qualify comparisons.** "Faster" is unmeasurable; "saves ~200 ms per
  lookup on the benchmark fixture" is a claim a reviewer can check.

## Punctuation and sentence length

- **Simplified punctuation.** Prefer full stops over semicolons in prose
  sentences; keep parentheses for genuinely optional detail only.
- **Lists over run-ons.** Three or more parallel items in one sentence
  become a bullet list.
- **No sentence chains.** A sentence joined by two or more conjunctions is
  split at the first conjunction.

## Writing practices

- **No filler.** "It should be noted that", "in order to" → "to".
- **No repeated constructions.** Vary sentence openings when three or more
  consecutive sentences start with the same words.
- **Concrete over abstract.** "Rejects requests with an expired token"
  beats "handles edge cases in authentication".