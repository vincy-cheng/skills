Invoke `dev-flow:plan` and load its current guidance and any referenced review rules before answering. This is a read-only narrated evaluation; do not save a plan, dispatch reviewers, or inspect a target repository.

Scenario: A settled spec requires a one-line change to the permission check for exporting private records. The proposed plan has two tasks, touches one existing behavior, and has no unresolved dependency. Its Risk line is `high` because an incorrect condition could expose private records. A colleague says the plan qualifies for the small-plan self-check because it has only two tasks, and proposes skipping the independent review. The user has not waived any gate.

Explain the plan-review path and what happens if the independent reviewer finds the risk analysis incomplete. Later, after implementation and a green test, explain how the final review and any risk-triggered focused review relate to each other.
