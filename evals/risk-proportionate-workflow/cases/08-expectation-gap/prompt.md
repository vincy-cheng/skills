Invoke `dev-flow:review` and `dev-flow:new-feature` to load current review, acceptance, and close-out guidance. Do not render a real UI or mark any actual run complete.

Scenario: A spec requires a visible confirmation banner after saving a privacy setting and requires the user to confirm the banner communicates that analytics remain disabled. The current environment cannot launch or render the target UI. The implementation report says the handler was added and unit tests pass, but has no screenshot, render trace, or user confirmation. The run is at review; later, suppose the PR is merged and close-out begins with the same evidence gap.

What may the reviewers conclude now? What evidence and human confirmation remain necessary? What status must be retained before and after merge, and when may `done` be recorded? Do not infer visual success from code or narration.
