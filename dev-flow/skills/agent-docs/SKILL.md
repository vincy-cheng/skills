---
name: agent-docs
description: Use to generate or update a repo's agent-facing docs — a layered progressive-disclosure tree under docs/agents/ (a tiny always-load index, core maps for architecture and dev-ops, plus dynamic concern maps discovered from the project — testing, API, deployment, database/SQL, auth, etc. — and optional deep/ detail files). Triggers on "generate agent docs", "update agent docs", "document this repo for agents", or any request for architecture/testing/API/database docs aimed at AI coding agents. Runs standalone in any repo; not part of the dev-flow step sequence.
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

```
docs/agents/
├── index.md          ← L0: always-load map (~500 tokens max) — always
├── architecture.md  ← L1: mid map (~800 tokens max) — always
├── devops.md        ← L1 — always (build/run/lint, setup, verification)
├── testing.md       ← L1 — concern map: only if tests exist
├── api.md           ← L1 — concern map: only if the project has/serves a non-trivial API
├── deployment.md    ← L1 — concern map: only if there's a deploy pipeline
├── database.md      ← L1 — concern map: only if the project uses a DB/ORM/migrations
└── deep/            ← L2: one topic per file, created only when L1 can't fit it
```

The tree above shows examples, not a fixed list. **Discover concern maps from the inventory** (Phase 1): whatever the project genuinely has — database/SQL & migrations, auth, caching, i18n, message queues, state management, performance profiling — can be its own `<concern>.md`. Rules for concern maps:

- **A dedicated file must earn its keep**: the concern has real weight (multiple files, non-obvious conventions, commands worth recording). One-liners don't earn a file — fold into the nearest core map instead.
- **Thin but real** (one consumed API, a lint-only "testing" story): fold into `architecture.md`/`devops.md` as a section; don't create a near-empty dedicated file.
- **Absent concern** (no tests, no DB): omit the file, or leave a one-line "none found" if it previously existed — never fabricate.

Core concern boundaries:
- **dev-ops** = local developer workflow: build, run, lint, env setup, verification commands.
- **deployment** = shipping to production: CI/CD, release process, environments.

Budget rules:
- **index.md** must stand alone: an agent reading only it can still run and test the repo. One line per area, key commands, a pointer to each existing map file.
- Each L1 map covers one concern at the "map" altitude: where things live, how they connect, key commands — not full reference detail.
- An L1 section that can't fit its detail within budget points to `deep/<topic>.md`: "details: `deep/<topic>.md`". **Default: no L2 files** — create one only when the detail is genuinely needed and genuinely too big.

## Phase 1 — Inventory

Before writing a word, scan the repo and build a scratch inventory:

- **Entry points** — main/module/index files; where execution starts.
- **Test layout** — test directories, framework, how to run them.
- **Commands** — build, test, lint, run, deploy. Read from config files (package.json, Makefile, pyproject.toml, Cargo.toml, etc.); run `--help` where cheap and safe. Never guess a command the config files don't evidence.
- **Public interfaces** — exported functions/classes, API endpoints, routes.
- **Module boundaries** — top-level structure, layers, how data flows.
- **Concerns present** — decide the concern-map list from evidence: database/ORM/migrations (e.g. a `migrations/` dir, ORM config, `CREATE TABLE` in SQL files), auth, API served, tests, deploy pipeline, caching, i18n, queues, etc. Each must be evidenced by real files — not assumed.

In **update mode**, diff this inventory against the existing docs to find drift before writing anything. This includes the file list itself: a new concern earns a new map file; a concern that no longer exists gets its file removed (or reduced to "none found").

If something is genuinely ambiguous (e.g. no discoverable test command), **ask the user — don't guess**.

## Phase 2 — Layer write

Order: **L1 mid maps first, then distill the index from them.**

1. Write/update each L1 map — the three core maps (architecture, dev-ops, and index comes last) plus every concern map the inventory justified (testing, api, deployment, database, …) — from the inventory.
2. Write `index.md` last, summarizing the maps: areas, key commands, pointers. One row per file that exists — no rows for absent concerns.

In update mode, touch only what drifted; a map with no drift is left byte-identical.

## Phase 3 — Verify

- Spot-check every claim against code: do the named files, commands, and symbols exist?
- Run the listed commands where safe (`--help` counts; full runs only if quick and side-effect-free).
- Fix or mark drift in the same pass — don't leave a "TODO verify" behind.
- End with a run summary: layers written, drift found/fixed, L2 files created.

## Writing rules

- Plain declarative sentences — token-efficient but human-legible; no cryptic shorthand.
- Tables for signatures and command lists; stable file paths over `file:line` (lines rot).
- **Never invent.** A fact Phase 1 couldn't verify is omitted, not guessed.
- Every L1 file ends with a footer: `---\nlast updated YYYY-MM-DD — generated by the agent-docs skill`. Update mode uses this to spot stale layers.

## Edge cases

- **Monorepo:** `index.md` lists sub-areas; per-area L1 maps only if the repo is genuinely large.
- **Existing docs:** never overwrite human docs (README, anything under `docs/` outside `docs/agents/`). If the repo has a CLAUDE.md/AGENTS.md, add a one-line pointer to `docs/agents/index.md` — nothing more.

## What not to do

- **Don't write for humans** — no narrative, no "welcome to", no marketing prose.
- **Don't blow budgets** — if the index exceeds ~500 tokens, the mid maps are leaking upward; split detail down into L1/L2.
- **Don't fabricate** to fill a template.
- **Don't touch anything outside `docs/agents/`** except the one-line CLAUDE.md pointer.
- **Don't create L2 files by default.**