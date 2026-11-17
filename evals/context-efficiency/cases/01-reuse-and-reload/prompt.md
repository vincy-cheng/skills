Invoke `dev-flow:new-feature` to load the plugin-owned guidance for this narrated evaluation. Use the runtime-resolved plugin location supplied by the invoked skill or command, including its expanded absolute engine path. Resolve reference links from their owning file, not the fixture working directory, and read the required source directly. This source-loading step is allowed before the task below; do not start or resume a real workflow, inspect a real target repository, or dispatch workers. The task below overrides unrelated workflow actions. If a required source cannot be read, report that failure instead of inventing its contents.

Read the owning Context reuse / isolated-brief / evidence rules in the loaded skill and its referenced `references/model-routing.md` before answering. Do not copy unrelated workflow history into the answer.

For each situation below, answer with only the action and one reason:

1. The same reference was loaded earlier in this session and has not changed.
2. The same reference was loaded earlier, but its file now has a different content hash.
3. The same reference was loaded earlier, but the file is now unavailable.
4. The same reference was loaded earlier, but the relevant context was lost after compaction and its version cannot now be established.

Do not run any external tooling. Answer only the four actions and reasons.
