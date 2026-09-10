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

Core concern boundaries:
- **dev-ops** = local developer workflow: build, run, lint, env setup, verification commands.
- **deployment** = shipping to production: CI/CD, release process, environments.

Budget rules:
- **INDEX.md** must stand alone: an agent reading only it can still run and test the repo. Budget: ~500 tokens (≈2 KB — verify with `wc -c`). A line that serves only one area belongs in that area's L1 map, not here. If it does not fit that shape, move the detail down a level — that is the design working, not a failure. One line per area, key commands, a pointer to each existing map file.
- Each L1 map covers one concern at the "map" altitude: where things live, how they connect, key commands — not full reference detail. Budget: ~800 tokens (≈3 KB — verify with `wc -c`). Detail that exceeds it points to `DEEP/` (next bullet).
- An L1 section that can't fit its detail within budget points to `DEEP/<TOPIC>.md`: "details: `DEEP/<TOPIC>.md`". **Default: no L2 files** — create one only when the detail is genuinely needed and genuinely too big.

## Phase 1 — Inventory

Before writing a word, scan the repo and build a scratch inventory:

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
- Run the listed commands where safe (`--help` counts; full runs only if quick and side-effect-free).
- Fix or mark drift in the same pass — don't leave a "TODO verify" behind.
- End with a run summary: layers written, drift found/fixed, L2 files created.

## Writing rules

- **Structural diagrams are Mermaid, never ASCII art.** Any architecture/flow/data-flow diagram goes in a fenced `​```mermaid` code block (`flowchart`, `sequenceDiagram`, `C4Context`, … — pick the type that fits). No box-drawing ASCII, no aligned columns of `┌─┐`/`▲`/`│` — they only read in the exact font that drew them and break everywhere else. Mermaid renders in chat, GitHub, and editors, and survives reflow. A diagram must still be **accurate before pretty**: nodes are real files/modules/services with stable names (paths over `file:line`), edges are actual call/data flow — never invent an edge the code doesn't have. Keep charts small: a diagram a reader can't take in at one glance belongs split per concern or expressed as a table. **Avoid long linear chains** (`A --> B --> C --> D --> E …`) — they render as one skinny hard-to-read line. Prefer shape over sequence: branch into parallel lanes where the flow genuinely branches, group related nodes with `subgraph`, and if a chain has more than ~4 hops, either compress intermediate hops into one labeled edge (`A -->|build + deploy| D`) or split the diagram per concern. In **update mode**, an existing ASCII-art diagram counts as drift — replace it with Mermaid in the same pass.
- Plain declarative sentences — token-efficient but human-legible; no cryptic shorthand.
- Tables for signatures and command lists; stable file paths over `file:line` (lines rot).
- **Never invent.** A fact Phase 1 couldn't verify is omitted, not guessed.
- **Each fact has exactly one canonical home** — the most relevant map. Other files may carry at most one line plus a pointer to it. When distilling INDEX, summarize the pointer, never restate the fact.
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