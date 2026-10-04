# cost.md — the full authoring spec (new-idea skill)

Supports **dev-flow:new-idea**. Applies **only** to runs where the user answered "include" to cost research (Rules §1) — for a declined idea this file is never loaded. Load this file before writing (or reviewing) an idea folder's `cost.md`.

## What goes in (only when the user opted in)

This whole section applies **only when the user answered "include" in Rules §1** — if they declined, skip the file entirely and don't do pricing research. Capture what the idea **costs**, grounded only in facts from `research.md` or user input:

- **Per-service pricing** — vendor, tier name, monthly price, and what the tier includes (quota, rate limits, extras like priority support or batch endpoints).
- **Official link per number** — every price and quota row carries its source URL (the vendor's official pricing/docs page, e.g. `https://vendor.com/pricing`). A number without a link is unverified — either add the link or mark it unknown. This keeps numbers checkable and shows readers at a glance what's gone stale. Applies to **both tables**: the per-vendor tier tables (Source column) and the usage-spend table (Sources line under it, one official pricing URL per service).
- **Verify before writing, ask when you can't.** Don't write a number from memory as fact. Verify it live against the official page: try WebFetch/WebSearch first; if they fail (empty results, 404, tool down), fall back to `curl -sL <url>` (cross-platform — macOS, Windows 10+, Linux) and read the returned HTML. Some pages render prices client-side (SPAs) and curl will return no figures. When verification fails, **ask the user for the pricing info** (e.g. "I couldn't verify Cloudflare Workers pricing — can you paste the tier/price?") — they often have a console, invoice, or docs at hand. If the user can't supply it either, mark it `_unverified — check <url>_` or an open question. Never write recall as fact; an honest unknown beats a confident stale number.
- **Consistency with research.md** — source URLs in `cost.md` must match the URLs already recorded in `research.md`; research.md is the single source of truth for links. (If research.md has a typo'd URL, fix it there first.)
- **Full-stack coverage** — cost every service the architecture touches, not just third-party APIs. Pull the complete stack from `design.md`: compute (Cloud Run, Lambda, Vercel…), scheduling/queueing (Cloud Scheduler, Cloud Tasks, cron…), storage (Firestore, S3, Postgres…), and external APIs. Each gets its own pricing rows — an automation tool might have four Google services that are each "basically free" until they're not. Every service named in `design.md`/`plan.md` appears in `cost.md`, even if just to say $0 / no cost.
- **Free options** — call/req/day limits, and what breaks when you exceed them.
- **Overage / per-use costs** — per-credit or per-request pricing above quota.
- **Hardware / one-off costs** — device, board, or setup costs, when the idea is physical.
- **Recommended path** — the cheapest viable starting point, and when it makes sense to upgrade.
- **Usage-based spend — daily AND monthly, per scenario, across the whole stack.** Tier prices alone don't say what the idea costs to run. Project actual spend at usage levels (e.g. light / typical / heavy): estimate per-service usage per day, then show **cost/day** and **cost/month** (30-day month) per service **and totaled**. Flat-monthly services show a flat row (`$29/mo = flat`). The scenarios often reveal **pivot points** — usage levels where a free-tier architecture stops being free (Firestore writes, Run request counts) and the cheapest path changes; call those out explicitly ("free up to ~N/day, then Cloud Run requests dominate"). A $0-total at every level is itself a finding — say it. Example shape for a stack (automation tool: Cloud Scheduler → Cloud Tasks → Cloud Run → Firestore + a weather API):

  ```markdown
  | Scenario | Scheduler | Tasks | Cloud Run | Firestore | Weather API | Total/day | Total/month |
  |---|---|---|---|---|---|---|---|
  | Light (1 city, hourly) | $0 | $0 | $0 | $0 | $0 | $0 | $0 |
  | Typical (50 cities, hourly) | $0 | $0 | $0 | ~$0.05 | $0 | ~$0.05 | ~$1.50 |
  | Heavy (500 cities, every 10 min) | ~$0.10 | $0 | ~$0.40 | ~$0.60 | $0 | ~$1.10 | ~$33 |

  Sources: Cloud Scheduler https://cloud.google.com/scheduler/pricing · Cloud Tasks https://cloud.google.com/tasks/pricing · Cloud Run https://cloud.google.com/run/pricing · Firestore https://cloud.google.com/firestore/pricing · Weather API https://open-meteo.com/en/docs
  ```

  (Figures illustrative — derive them from the verified tier tables above. Every column's price basis comes from that service's tier table, which carries the official link — the **Sources line repeats each service's official pricing URL** so the spend table stands alone when shared. Pivot points to call out: Firestore writes exhaust their free tier around Typical; Cloud Run request-minutes dominate at Heavy.)

- **Show the calculation, not just the result.** Every cost cell must be traceable: show the arithmetic in a "How" note, a per-scenario breakdown, or inline — `2,000 calls × $0.002/call = $4.00/day`, `(10,000 − 1,000 free) × $0.002 = $18/day`, `within Free 1,000/day → $0`. A reader must be able to re-derive every number from the tier tables + the usage estimate without trusting you. A result with no shown math is an assumption hiding as a fact.
- **Unknowns** — mark anything unpriced as an open question; never invent a number.

A small table per vendor (with a Source column for the official link) **plus the usage-spend table** plus a one-line recommendation is the right shape:

```markdown
| Tier | Price | Includes | Source |
|---|---|---|---|
| Free | $0/mo | 1,000 calls/mo, 100 req/day | https://vendor.com/pricing |
| Starter | $19/mo | 10,000 calls/mo, 100 items/req | https://vendor.com/pricing |
```

If the idea genuinely has no running costs, write one line saying so — the slot still gets a file (when opted in). If the user declined `cost.md`, don't create the file at all — record pricing unknowns as open questions in `research.md` instead.
