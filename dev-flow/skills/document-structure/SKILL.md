---
name: document-structure
description: Use to generate or update a repo's agent-facing docs — a layered progressive-disclosure tree under docs/agents/ (a tiny always-load index, core maps for architecture and dev-ops, plus dynamic concern maps discovered from the project — testing, API, deployment, database/SQL, auth, etc. — and optional deep/ detail files). Triggers on "document this repo", "generate agent docs", "update agent docs", "document this repo for agents", or any request for architecture/testing/API/database docs aimed at AI coding agents. Runs standalone in any repo; not part of the dev-flow step sequence.
---

# Agent docs

Generate and maintain this repo's **agent-facing documentation**: a layered tree under `docs/agents/` built for progressive disclosure — an agent loads the tiny index first, a mid-level map only when working in that area, deep detail only when truly needed. The docs are written for AI coding agents; humans read the README, but keep the prose human-legible for free (plain sentences, no cryptic shorthand).

The skill is **stateless** — the docs themselves are the state. No state file, no gate, no step sequence.

## Modes

Choose at entry, before doing anything:

- `docs/agents/` **absent** → **generate mode**: full build, all phases.
- `docs/agents/` **present** → **update mode**: run Phase 1 to find drift, then patch **only** the drifted sections. Never rewrite a whole file wholesale; never delete content the inventory didn't invalidate.

## The tree and its budgets

Two tiers: **core maps** (always written) and **concern maps** (written only when the inventory finds that concern — the tree is **dynamic, shaped by the project**).

Map filenames are **ALL-CAPS** (`INDEX.md`, `ARCHITECTURE.md`, …), README.md-style.

The `docs/agents/` subdirectory is load-bearing, not cosmetic — keep it mandatory, never flatten to `docs/`. It does double duty: (1) **mode detection** — entry logic checks for `docs/agents/` existence to choose generate vs update; a flat `docs/` layout breaks that. (2) **scope boundary** — "never touch anything outside `docs/agents/`" relies on the directory edge; a flat layout mixes agent maps with human docs and pollutes the agent tree on every update run.

```
docs/agents/
├── INDEX.md          ← L0: always-load map (~500 tokens, ≈2 KB — verify with wc -c) — always
├── ARCHITECTURE.md   ← L1: mid map (~800 tokens, ≈3 KB — verify with wc -c) — always
├── DEVOPS.md        ← L1 — always (build/run/lint, setup, verification)
├── TESTING.md       ← L1 — concern map: only if tests exist
├── API.md           ← L1 — concern map: only if the project has/serves a non-trivial API
├── DEPLOYMENT.md    ← L1 — concern map: only if there's a deploy pipeline
├── DATABASE.md      ← L1 — concern map: only if the project uses a DB/ORM/migrations
└── DEEP/            ← L2: one topic per file, created only when L1 can't fit it
```

The tree above shows examples, not a fixed list. **Discover concern maps from the inventory** (Phase 1): whatever the project genuinely has — database/SQL & migrations, auth, caching, i18n, message queues, state management, performance profiling — can be its own `<CONCERN>.md`. Rules for concern maps:

- **A dedicated file must earn its keep**: the concern has real weight (multiple files, non-obvious conventions, commands worth recording). One-liners don't earn a file — fold into the nearest core map instead.
- **Thin but real** (one consumed API, a lint-only "testing" story): fold into `ARCHITECTURE.md`/`DEVOPS.md` as a section; don't create a near-empty dedicated file.
- **Absent concern** (no tests, no DB): omit the file, or leave a one-line "none found" if it previously existed — never fabricate.

Canonical concern→filename mapping (ALL-CAPS):

| Concern | File |
| --- | --- |
| build/run/lint/setup | DEVOPS.md |
| shipping/CI-CD | DEPLOYMENT.md |
| tests | TESTING.md |
| serves HTTP | API.md |
| DB/ORM/migrations | DATABASE.md |

Unlisted concerns: `<CONCERN>.md`, ALL-CAPS from the concern name.

Core concern boundaries:
- **dev-ops** = local developer workflow: build, run, lint, env setup, verification commands.
- **deployment** = shipping to production: CI/CD, release process, environments.

Budget rules:
- **INDEX.md** must stand alone: an agent reading only it can still run and test the repo. Budget: ~500 tokens (≈2 KB — verify with `wc -c`). A line that serves only one area belongs in that area's L1 map, not here. If it does not fit that shape, move the detail down a level — that is the design working, not a failure. One line per area, key commands, a pointer to each existing map file.
- Each L1 map covers one concern at the "map" altitude: where things live, how they connect, key commands — not full reference detail. Budget: ~800 tokens (≈3 KB — verify with `wc -c`). Detail that exceeds it points to `DEEP/` (next bullet).
- An L1 section that can't fit its detail within budget points to `DEEP/<TOPIC>.md`: "details: `DEEP/<TOPIC>.md`". **Default: no L2 files** — create one only when the detail is genuinely needed and genuinely too big.

## Phase 1 — Inventory

Before writing a word, scan the repo and build a scratch inventory:

- **README** — read it first; it is often the best evidence for commands and intended workflow.
- **Entry points** — main/module/index files; where execution starts.
- **Test layout** — test directories, framework, how to run them.
- **Commands** — build, test, lint, run, deploy. Read from config files (package.json, Makefile, pyproject.toml, Cargo.toml, etc.); run `--help` where cheap and safe. Never guess a command the config files don't evidence.
- **Public interfaces** — exported functions/classes, API endpoints, routes.
- **Module boundaries** — top-level structure, layers, how data flows.
- **Concerns present** — decide the concern-map list from evidence: database/ORM/migrations (e.g. a `migrations/` dir, ORM config, `CREATE TABLE` in SQL files), auth, API served, tests, deploy pipeline, caching, i18n, queues, etc. Each must be evidenced by real files — not assumed.

In **update mode**, diff this inventory against the existing docs to find drift before writing anything. This includes the file list itself: a new concern earns a new map file; a concern that no longer exists gets its file removed (or reduced to "none found"). **Naming drift counts as drift**: a tree with lowercase map filenames (`index.md`, `architecture.md`, …) is migrated to the ALL-CAPS names in this pass — `git mv` each file, then fix every pointer to it (`INDEX.md` rows, agent-instruction pointers, cross-references) in the same pass.

**Update-mode shortcut — scope by what changed.** Before re-scanning everything: read the newest `last updated` footer across the maps, then check what changed since (`git log --since=<date>`, or invoke `dev-flow:whats-new` — it gathers the same history + doc-drift check). If nothing in the window touches an area a map covers, that map is verified-current; scope Phase 1 to the changed areas only.

If something is genuinely ambiguous (e.g. no discoverable test command), **ask the user — don't guess**.

## Phase 2 — Layer write

Order: **L1 mid maps first, then distill the index from them.**

1. Write/update each L1 map — the three core maps (architecture, dev-ops, and index comes last) plus every concern map the inventory justified (testing, api, deployment, database, …) — from the inventory.
2. Write `INDEX.md` last, summarizing the maps: areas, key commands, pointers. One row per file that exists — no rows for absent concerns.

In update mode, touch only what drifted; a map with no drift is left byte-identical.

## Phase 3 — Verify

- Spot-check every claim against code: do the named files, commands, and symbols exist?
- Verify every pointer both ways: each `INDEX.md` row names a file that exists, and each agent-instruction file's `docs/agents/INDEX.md` pointer has a live target. Fix in the same pass — a dangling pointer is worse than no pointer.
- **Duplication and contradiction review — after fixing facts and pointers:** for each fact that appears in more than one file, keep exactly one canonical copy (per the single-source rule) and reduce the others to a pointer; remove anything that contradicts a decision already recorded elsewhere (e.g. agent-instruction files). This review runs on every write, in both generate and update mode — update mode's "touch only what drifted" does not exempt it, because a freshly patched section can introduce duplication the drift diff won't reveal.
- **Verification allowlist:** build/test/lint type commands may be run in full. Side-effectful commands (seed, migrate, deploy, anything writing to external state) get `--help` only. If a command is ambiguous, do not run it — spot-check its evidence in config files instead.
- Fix or mark drift in the same pass — don't leave a "TODO verify" behind.
- End with a run summary: layers written, drift found/fixed, L2 files created.

## Writing rules

- **Mermaid is for files humans will open** (README, `docs/<topic>.md`), never `docs/agents/` — when actually writing a diagram, load `references/mermaid.md` first.
- Plain declarative sentences — token-efficient but human-legible; no cryptic shorthand.
- Tables for signatures and command lists; stable file paths over `file:line` (lines rot).
- **Never invent.** A fact Phase 1 couldn't verify is omitted, not guessed.
- **Each fact has exactly one canonical home** — the most relevant map. Other files may carry at most one line plus a pointer to it. When distilling INDEX, summarize the pointer, never restate the fact.
- **Record the why next to the what.** Decisions discovered during inventory (auth model choices, deliberate omissions/known-broken states, config sourced from secrets rather than env, non-obvious constraints) go into the most relevant map, marked as a decision — not into a separate ADR directory. Format: the decision + one line of why. Example in ARCHITECTURE.md: "DB password is overridden from Secret Manager — the DB password never lives in `.env`." A decision that can't fit any existing map earns a new concern map (e.g. `DECISIONS.md`) only when there are several; one or two live in the nearest map.
- Every L1 file ends with a footer: `---\nlast updated YYYY-MM-DD — generated by the document-structure skill`. Update mode uses this to spot stale layers.

## Edge cases

- **Monorepo:** `INDEX.md` lists sub-areas; per-area L1 maps only if the repo is genuinely large.
- **Existing docs:** never overwrite human docs (README, anything under `docs/` outside `docs/agents/`). For each agent-instruction file the repo already has, add a one-line pointer to `docs/agents/INDEX.md` — nothing more. Agent-instruction files include: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `QWEN.md`, `COPILOT.md` / `.github/copilot-instructions.md`, `.cursorrules` / `.cursor/rules/`, `.windsurfrules`. Only add the pointer to files that exist — never create one; never modify any other content in them.
- **Pointer ordering — never point at nothing.** Write the `docs/agents/` tree first, pointers last: only add pointer lines to agent-instruction files after `docs/agents/INDEX.md` exists on disk. If a generate run fails midway, the pointer step is skipped — no dangling pointers.
- **Dangling pointers (update mode — and generate mode too):** check the reverse direction too — every agent-instruction file that contains a `docs/agents/INDEX.md` pointer must have a live target. If `docs/agents/INDEX.md` is missing but pointers exist, either regenerate the tree or remove the pointers — ask the user which; never leave a pointer pointing at nothing. Conversely, if the tree exists but a concern map referenced by `INDEX.md` is missing, that's drift: rebuild the row or restore the file in this pass. In generate mode this case self-heals — but before writing, note any existing pointers: the rebuilt tree must land at the path they name.

## What not to do

- **Don't write for humans** — no narrative, no "welcome to", no marketing prose.
- **Don't blow budgets** — see the `wc -c` proxy at the budget definition site.
- **Don't fabricate** to fill a template.
- **Don't touch anything outside `docs/agents/`** except the one-line pointer per existing agent-instruction file (see *Edge cases*).
- **Don't create L2 files by default.**