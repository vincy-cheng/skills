Invoke `dev-flow:new-feature` to load the plugin-owned guidance for this narrated evaluation. Use the runtime-resolved plugin location supplied by the invoked skill or command, including its expanded absolute engine path. Resolve reference links from their owning file, not the fixture working directory, and read the required source directly. This source-loading step is allowed before the task below; do not start or resume a real workflow, inspect a real target repository, or dispatch workers. The task below overrides unrelated workflow actions. If a required source cannot be read, report that failure instead of inventing its contents.

Read the owning Context reuse / isolated-brief / evidence rules in the loaded skill and its referenced `references/model-routing.md` before answering. Do not copy unrelated workflow history into the answer.

Write one dispatch brief for a fresh subagent. Include only enough context for the job:
Task: add one test that fails before `sum()` is public and passes after it.
Constraints: follow the repository's test style and do not refactor unrelated code.
Relevant paths: `src/sum.ts`, `src/sum.test.ts`.
Interface from an earlier task: `export function sum(values: number[]): number`.
The repository output-style contents are:
    Keep the conclusion first. Keep one term per concept. Do not add unrelated text.
Report contract: write the full command output to `reports/task-7.md`; return status, one test line, and the report path.
Also remove unrelated conversation history.
