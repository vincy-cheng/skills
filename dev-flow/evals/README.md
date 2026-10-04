# dev-flow eval suites

Behavioral evals for dev-flow's skills, run with `claude plugin eval`. Each
suite targets one skill's contract; cases are narrated fixtures + two-layer
LLM graders (see any `cases/*/graders/grader.md` for the shape).

| Suite | Skill | Cases | What it pins |
|-------|-------|-------|--------------|
| `brainstorm` | `dev-flow:brainstorm` | 4 | interview-first, idea-folder confirmation, iron law, spec path |
| `plan` | `dev-flow:plan` | 5 | contract-complete, flow chart, no-handoff, no-spec refusal |
| `tdd` | `dev-flow:tdd` | 4 | red-first, atomic steps, no skipping ahead, commit discipline |
| `new-feature` | `dev-flow:new-feature` | 4 | hard gate: entry status, refusal on mismatch, red-loop rewind, sub-skill no-handoff |
| `review` | `dev-flow:review` | 4 | R5 verdict contract: green/blue/yellow/red + follow-on action |

## How to run

Target the plugin by **path**, not name, and the suite via `--eval-dir` below
the plugin root:

```bash
claude plugin eval /path/to/skills/dev-flow --eval-dir evals/new-feature
claude plugin eval /path/to/skills/dev-flow --eval-dir evals/review
```

Under a model proxy (e.g. OmniRoute), pass explicit model/judge overrides —
the default model resolution doesn't reach proxy-routed models:

```bash
claude plugin eval /path/to/skills/dev-flow --eval-dir evals/new-feature \
  --model <target-model> --judge-model <judge-model>
```

Results land under `dev-flow/evals/results/<timestamp>/` (`aggregate-result.json`;
`report.html` when the run produces one — observed layouts have varied).

## Known quirks

These are environment behaviors observed in prior runs — work within them;
don't change eval infrastructure to route around them (that's out of scope
until a dedicated issue says otherwise).

- **Two-layer grant.** `--allow-tools` is the only real grant; permission
  rules from settings are ignored by the eval harness. A `Bash` grant also
  triggers a PATH-EPERM precheck that can block commands unexpectedly. This
  is why these suites **narrate fixtures inside `prompt.md`** (state files,
  diffs, reports) instead of relying on setup commands — cases stay writable
  with a minimal (`Write`) grant.
- **Judge flakiness.** The LLM judge (e.g. `glm-5.3-flash`) can FAIL an
  objectively good response — graders demand the agent's exact words, and the
  judge sometimes misses them. A single FAIL where the transcript plainly
  satisfies the B-items is grounds for **re-running the case once**, not for
  loosening the grader or changing code.

## Grading convention (all suites)

Two layers, strict and binary:

- **Layer 1** — behavior checks (B1..Bn), each Y/N with quoted evidence from
  the response. ALL must pass. The newer suites (`new-feature`, `review`) add
  a suite-specific **gate-violation rule** section that makes the guarded
  failure modes fail deterministically regardless of phrasing; the older
  suites use looser case-specific sections to the same effect.
- **Layer 2** — quality rubric (Q1/Q2, 0–2), scored only if Layer 1 fully
  passes.
- **Verdict** — `PASS`/`FAIL` on the first line.

## Future work

- **execute-tasks mode-split suite** — evals for the inline-vs-subagent
  recommendation from task shape (count / file spread / coupling), including
  the user-override path. Mentioned in issue #43's summary but kept out of
  its strict scope; candidate follow-up suite.