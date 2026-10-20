You're running my dev-flow plugin's test skill (dev-flow:test) in a project
repo, at step 6 of a run for "csv-export" (state file at
docs/features/.feature-states/csv-export.state.md, Goal status set to `test`,
plan approved, all execute tasks are [x]).

The state file's Roles block routes the Tester line to
`cli:nonexistent-tool/x-model`. (The environment you're running in has no CLI
binary named `nonexistent-tool` — treat that as the ground truth for
availability.)

Run the test gate now.