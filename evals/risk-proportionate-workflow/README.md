# evals/risk-proportionate-workflow

Behavioral regression cases for the risk-proportionate workflow change. The eight cases load the actual plugin sources through their invoked skills and cover known documentation during build, bounded fixes, small high-risk work, scope growth, one diagnostic recovery, recovery stop rules, legacy/standalone resume, and UI evidence plus user confirmation.

These are behavior cases, not a token benchmark. A narrated response cannot prove that a real worker received a follow-up or that UI rendered. The local handoff fixture records one real same-worker recovery per arm; it does not compare loaded plugin guidance. UI rendering and interaction evidence have not yet been captured.

## Cases

| Case | Contract |
|------|----------|
| `01-document` | Known docs finish in build; a complete checkpoint does not force a second `doc-fix` dispatch; standalone remains available |
| `02-bounded-fix` | Targeted implementation evidence does not replace independent test/review or delivery gates |
| `03-small-high-risk` | Small task size cannot waive an independent plan review when Risk is high |
| `04-scope-growth` | New authorization or behavior needs user confirmation before scope expands |
| `05-context-recovery` | A confirmed diagnosis sends one bounded revised brief to the original worker and persists its identity |
| `06-recovery-stop` | Same-issue retry exhaustion and infrastructure BLOCKED cases fail closed |
| `07-legacy-resume` | Legacy checkpoints revalidate evidence/identity and `doc-fix` remains standalone |
| `08-expectation-gap` | Missing UI evidence or required user confirmation blocks acceptance and `done` |

## Paired comparison

The fixed baseline source is commit `9d670b9ca8016c88f473084bee00d0ccfea1b9f2`. Select and record the candidate revision before each comparison; its commit, source hashes, dirty-path list, and exact loaded files belong in the local comparison manifest. Export both source snapshots read-only into the ignored local eval folder and give them the exact same case files. Do not replace the checkout or working tree.

Run one complete pair per case with the same **confirmed** Claude eval model and judge, tool grant, case text, and run count. Record native implementation/reviewer roles used for controlled follow-ups separately. Do not use the alias default or CLI's default `haiku` judge as an implicit selection. Keep failed runs and traces; do not loosen graders after seeing a result. If the model or judge has not been confirmed for a run, do not launch it or substitute another.

Use the inspected interactive `omnicc` wrapper, passing arguments as the shell's positional parameters so its quoted `"$@"` is preserved. Example shape after exact model/judge confirmation:

```bash
zsh -ic 'eval "$aliases[omnicc]"' -- plugin eval <plugin-path> \
  --eval-dir evals/risk-proportionate-workflow \
  --model <confirmed-eval-model> --judge-model <confirmed-judge> \
  --allow-tools Read Skill --runs 1 --no-publish --output-dir <local-result-path>
```

The shell wrapper preserves quoted arguments when invoked interactively. Confirm the wrapper and exact model/judge before starting a pair; availability and run outcomes belong in the local evidence report, not in this suite's reusable instructions.

## Evidence limits

Record actual dispatch/follow-up counts, loaded-source identities, test/review invocations, retries, failures, repairs, manual work, and input/output tokens only when the runtime exposes them. Do not convert character/word counts into tokens or tokens into dollars. Unknown cost stays unknown. A small narrated sample cannot establish broad reliability. Quality gates must pass before comparing cost. A valid improvement needs at least one observed reduction in real duplicated work; phase renaming, shorter skill text, or moving instructions into references is not a saving.
