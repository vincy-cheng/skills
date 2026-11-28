# Skills

`dev-flow` guides features and fixes from design through pull request review in Claude Code and Codex.

## Install and start

### Claude Code

```sh
/plugin marketplace add vincy-cheng/skills
/plugin install dev-flow@vincy-skills
```

Or install directly from GitHub:

```sh
claude plugin install https://github.com/vincy-cheng/skills.git
```

Start a feature or fix with `/new-feature <your idea>`. Run `/new-feature` without a new brief to resume the latest active run. The workflow uses the `gh` CLI to create GitHub issues and pull requests.

### Codex

Add the marketplace from GitHub:

```sh
codex plugin marketplace add vincy-cheng/skills
```

In Codex, open the **Plugins Directory**, select **Vincy Skills (Codex)**, and install `dev-flow`. Restart the Codex desktop app after installation. Invoke `$dev-flow:new-feature` with a brief to start, or without a new brief to resume the latest active run.

For local development, see [local Codex installation and updates](docs/agents/DEVOPS.md).

## How the workflow runs

| Phase | Work |
|-------|------|
| Define | Discuss the design, approve a spec and plan, then create a GitHub issue |
| Build | Implement with TDD and per-task commits, including confirmed repairs to affected docs |
| Verify | Run tests and review, then pass the documentation-consistency checkpoint |
| Deliver | Open or update the PR, run the PR readiness check, and wait for your manual merge before close-out |

Gitignored specs, plans, and run state live under `docs/features/`. The saved state lets you resume at the current step across all four phases. While the run is at `doc-fix`, resume revalidates Step 8 evidence. The transition `pr-review → merged` requires remote merge confirmation.

See the [architecture guide](docs/agents/ARCHITECTURE.md#the-pipeline) for status and recovery rules and the [workflow skill](skills/new-feature/SKILL.md) for all 11 steps.

## Optional configuration

Use the target repo's `.dev-flow/config.json` to override reviewer groups or set native Codex models. Bootstrap preserves existing `codex_reviewers` and `reviewers` settings. See [repo setup](skills/bootstrap/SKILL.md).

### Per-step reviewer groups

Configure `codex_reviewers` for Codex or `reviewers` for Claude Code. Every reviewer in a configured group must clear the step's verdict rules. Steps without a group, such as `main_review` in this example, use the existing reviewer selection.

```json
{
  "codex_reviewers": {
    "red_team": ["<native-model-a>", "<native-model-b>"],
    "plan_review": ["<native-model-a>"],
    "focused_review": ["<native-model-a>", "<native-model-b>"]
  },
  "reviewers": {
    "red_team": ["session", "claude:<model-name>"],
    "plan_review": ["session"],
    "focused_review": ["session", "claude:<model-name>"]
  },
  "codex_reviewer_model": "<available-native-model>",
  "codex_implementer_model": "<available-native-model>"
}
```

On Codex, `inline` uses the session model and `session` uses a native subagent. The confirmed implementation model is saved for resume. An unavailable model blocks dispatch. Claude Code uses `roles.implementer`. CLI routes are unchanged by the native settings.

See [model routing](references/model-routing.md#per-step-reviewer-groups) for valid lanes, fallback order, and review requirements.

### Custom CLI adapters

Register the absolute path to a local executable with `cli_adapters` in the target repo's `.dev-flow/config.json`. Select `cli:<adapter>/<exact-model-id>` for a supported role. Both hosts support custom implementers and testers. Claude Code can also use custom reviewers.

The adapter helper requires Python 3. Use native macOS isolation for single-process adapters or a pinned local Docker image for launchers that need subprocesses. The wrapper supplies backend model evidence, and its credential names are local configuration. See [custom CLI adapters](references/custom-cli-adapters.md).

## Idea capture and session help

- In Claude Code, run `/new-idea <idea>` to discuss an idea and draft research, design, and planning docs. To build from them, point `/new-feature` at the resulting folder. See the [idea capture skill](skills/new-idea/SKILL.md).
- Claude Code session help shows the current run in the status line and posts a toast when the step changes. Open **[ Flow ]** to view progress or resume an unfinished run. In the classic terminal renderer, run `/tui fullscreen` to enable button clicks.

## Contributing

Run `bash tests/check.sh` after editing skills or commands. For hook changes, run `claude plugin validate .` and `claude plugin test .`.

See the [repository guide](docs/agents/INDEX.md) for layout and development details and the [eval guide](evals/README.md) for behavioral checks.

## Acknowledgements

The `dev-flow` workflow and its early planning engine were inspired by [obra/superpowers](https://github.com/obra/superpowers). The plugin now provides its own skills for the workflow, and all artifacts stay under `docs/features/`.

The `tdd` skill's **seams** concept (testing at public boundaries rather than internals) comes from Kent Beck's *Test-Driven Development: By Example*, encountered through Matt Pocock's skill collections ([mattpocock-skills](https://github.com/mattpocock/skills)).

The `review` skill's clean-code pass draws on Robert C. Martin's *Clean Code*, [wojteklu's clean-code checklist](https://gist.github.com/wojteklu/73c6914cc446146b8b533c0988cf8d29), and the r/cleancode community guide; it is housed at `skills/review/references/clean-code.md`.

The `standardize-prose` skill's writing rules are adapted in spirit from ASD-STE100 Simplified Technical English Issue 9, owned by ASD — Aerospace, Security and Defence Industries Association of Europe; the skill paraphrases the rules and ships no STE text ([official PDF](https://www.asd-ste100.org/assets/files/ASD-STE100_ISSUE9.pdf)).
