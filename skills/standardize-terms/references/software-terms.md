# Software term list for spec and plan prose

> Original term list for software design docs, applying the
> one-word-one-meaning pattern of controlled technical English.
> Inspired by ASD-STE100 Simplified Technical English (Issue 9), owned by
> ASD — Aerospace, Security and Defence Industries Association of Europe.
> This list is original work — no STE dictionary entries are reproduced.
> Official standard: https://www.asd-ste100.org/assets/files/ASD-STE100_ISSUE9.pdf

How to use: for each entry, pick the preferred term at the start of a doc
(or keep the author's first choice) and fix every other occurrence to match.
Frozen entries are absolute — never rewritten in a cleanup pass.

## Frozen entry

- **Modals: shall, must, will, may.** These carry distinct force and are
  never swapped or rewritten: *must* binds the requirement, *will* predicts
  behavior, *may* permits, *shall* binds in standards-style prose. A cleanup
  pass treats them as opaque tokens.

## Term-pick entries (choose one per doc, apply everywhere)

- **component / module / unit** — pick one for a code unit; drop the others.
- **system** — the whole product under design; not a synonym for component.
- **configuration** — preferred in prose over "config" (keep "config" only
  in config-file names and code identifiers).
- **directory** — preferred over "folder" in technical prose.
- **parameter** — for values passed into a function; not "argument" and
  "parameter" interchangeably in the same doc.
- **endpoint** — an HTTP route; not "route" and "endpoint" mixed.
- **identifier** — a stable name for an entity; not "id", "key", and
  "identifier" for the same field in different sections.
- **user** — a human account; not "user" and "customer" and "account
  holder" interchangeably.
- **request / response** — the HTTP pair; not "call" for request.
- **client / server** — fixed roles; not "consumer"/"provider" in the same
  doc unless describing message queues, where those are the standard pair.
- **database** — the storage engine; "store" only as a verb.
- **schema** — the structure definition; not "model" for the same thing.
- **migration** — a schema change; not "migration" and "schema update" both.
- **token** — an auth credential; not "token" and "credentials" for one thing.
- **build** — producing artifacts from source; not "compile" when tools
  also bundle or transpile.
- **deploy** — placing artifacts into an environment; not "deploy" and
  "release" and "publish" interchangeably (reserve "release" for user-facing
  version cuts).

## Disambiguation entries (fix when both appear for one concept)

- **verify vs validate** — *verify*: the built thing matches the spec
  (tests). *validate*: input is well-formed before use. Keep the two apart.
- **test vs check** — *test*: automated assertion in the suite. *check*: a
  manual or shell inspection.
- **error vs failure** — *error*: a detected wrong condition (the thing
  thrown/returned). *failure*: a test or system outcome.
- **retry vs re-run** — *retry*: automatic re-attempt with policy. *re-run*:
  a human starts it again.
- **cache vs buffer** — *cache*: reuse optimization across requests.
  *buffer*: temporary holding within one operation.
- **auth vs authorization** — "auth" only as a prefix (auth middleware,
  auth flow); in prose use *authentication* (who you are) and
  *authorization* (what you may do) precisely.

## Pattern rules

- **One meaning per word.** A term listed here carries one meaning in the
  doc; if another sense is needed, the sentence names the second thing with
  a different word.
- **No part-of-speech drift.** If "cache" is the chosen noun, the verb form
  is "cache" too ("the client caches the response") — not "buffers" or
  "memoizes" in half the sentences.
- **No synonym drift under paraphrase.** Rewriting a sentence never swaps
  the doc's chosen term for a synonym; prose rules may restructure the
  sentence, but the nouns stay.
- **Code identifiers are out of scope.** This list standardizes prose only;
  file names, API paths, and code identifiers are never rewritten to match.