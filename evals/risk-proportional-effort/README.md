# evals/risk-proportional-effort

Behavioral eval suite for issue #108 (risk-proportional effort): plan-review
depth classification, Implementer context lifecycle (`shared` / `per-task` /
`not-used`), and their failure/resume paths. Run like the other suites:

```bash
claude plugin eval /path/to/plugin --eval-dir evals/risk-proportional-effort
```

Under a model proxy, pass `--model` / `--judge-model` overrides (see
`evals/README.md`).

## Cases

| Case | Pins |
|------|------|
| `01-small` | small eligibility → plan self-check; test + main review still independent; pass record contents |
| `02-ordinary` | ordinary plan → independent review; escalation-only risk recheck; shared recommendation with trade-offs confirmed by the user |
| `03-high-risk` | probe-triggered high tier; focused review scope (triggered categories only); honest waiver recording; yellow → fix-now/note-in-PR |
| `04-resume-and-escalate` | legacy state keeps per-task read-only; saved choices beat later config; repair escalation off the self-check path; the sanctioned 404 fallback is reported |
| `05-shared-lifecycle` | same-worker follow-up; delta-only briefs; live drift beats plan text and memory; coordinator check; shared never replaces independent gates |
| `06-unsupported-and-lost-worker` | CLI re-run ≠ shared (stop + alternatives); lost worker → preserve report/diff/verification + explicit choices; context overflow not a model-BLOCKED; unknown value stops |

## Bounded comparison method (old vs new)

The suite's cases pin the **new** contract's behavior. The run-local bounded
comparison (see the plan's Task 4) compares, for the same narrated run:

1. **Baseline** — a fixed pre-implementation commit, loaded read-only (or an
   isolated copy; never the user's worktree), with its actual guidance read
   from that commit's files. Record the version and the guidance content
   actually loaded — never the candidate's.
2. **Candidate** — the working tree's current contract.
3. Compare per the case's narrated decisions: classification, review
   dispatches, recommended lane/context, and recovery paths. **Same-model
   per-task and shared are recorded as separate rows** — a per-task sequence
   on the same model must not be reported as shared.
4. Record what is actually obtainable: dispatch count, approximate input
   context size, review findings, and any planted-defect misses. Raw token
   counts are not quota or billing evidence; a small sample is not a
   quality-no-regression proof. Untested items are listed as untested.
5. A narrated walkthrough is **not** evidence of a real same-worker
   follow-up; graders treat narrated shared-lifecycle answers as contract
   knowledge only. Real follow-up verification happens separately on a
   native path that actually supports it — read-only local capability checks
   first, then a bounded real follow-up under the run's confirmed roles; a
   missing prerequisite is recorded **blocked**, not skipped.

Results land under `docs/features/.eval/risk-proportional-effort/`
(gitignored) with the baseline/candidate versions and observed limitations —
never committed.
