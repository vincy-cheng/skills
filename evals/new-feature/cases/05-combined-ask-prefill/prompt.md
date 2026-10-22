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
    "reviewer": "session",
    "red-team": "session"
  }
}

I'm at the point of the run right before execute-tasks gets invoked. Take the
next step of the run.