Invoke `dev-flow:whats-new` to load the plugin-owned guidance for this narrated evaluation. Use the runtime-resolved plugin location supplied by the invoked skill or command, including its expanded absolute engine path. Resolve reference links from their owning file, not the fixture working directory, and read the required source directly. This source-loading step is allowed before the task below; do not start or resume a real workflow, inspect a real target repository, or dispatch workers. The task below overrides unrelated workflow actions. If a required source cannot be read, report that failure instead of inventing its contents.

Use the `whats-new` skill to summarize this narrated run for the project lead. Do not claim you inspected real files or GitHub.

Narrated evidence:
- The release branch contains the completed fix and docs update.
- The CI check passed on the release commit.
- The required staging deployment did not run because the staging credential is missing.
- Next action: the release owner must provide the credential and rerun staging before release.
- No production deployment occurred.
