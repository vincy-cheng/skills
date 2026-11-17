Invoke `dev-flow:whats-new` to load the plugin-owned guidance for this narrated evaluation. Use the runtime-resolved plugin location supplied by the invoked skill or command, including its expanded absolute engine path. Resolve reference links from their owning file, not the fixture working directory, and read the required source directly. This source-loading step is allowed before the task below; do not start or resume a real workflow, inspect a real target repository, or dispatch workers. The task below overrides unrelated workflow actions. If a required source cannot be read, report that failure instead of inventing its contents.

Run the `whats-new` skill as a standalone request. No dev-flow run is active. Summarize this narrated evidence for the maintainer; distinguish it from any real inspection.

Fixture:
- A local commit `abc1234` adds CSV export and a regression test.
- The narrated test result is 18 passed, 0 failed.
- No PR or deployment evidence is provided.
- The maintainer needs the change, test result, and what remains unknown.
