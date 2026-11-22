Invoke `dev-flow:new-feature` first and use Read on `skills/new-feature/SKILL.md` from the runtime plugin base returned or resolved by the Skill invocation. The inline state, reports, roles, and config below are authoritative for this narrated fixture; do not inspect an empty runtime sandbox or filesystem for them. Answer only the workflow's exact next actions and state changes. Allow only Skill and Read for source guidance; do not inspect external systems, call GitHub, dispatch workers, write or edit files, or perform operational actions.

You're running my dev-flow plugin in a project repo, mid-run for "csv-export"
(state file at docs/features/.feature-states/csv-export.state.md, Goal status
issue — spec and plan are approved and the issue exists; the plan has 6 tasks
touching ~8 files, mostly mechanical, well-specified).

This repo's .dev-flow/config.json contains:

{
  "dev_branch": "dev",
  "roles": {
    "implementer": "claude:github/gpt-5.4",
    "tester": "session",
    "reviewer": "session"
  }
}

I'm at the point of the run right before execute-tasks gets invoked. Take the
next step of the run.