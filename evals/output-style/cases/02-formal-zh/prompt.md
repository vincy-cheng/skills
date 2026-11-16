Invoke `dev-flow:new-feature` to load the plugin-owned guidance for this narrated evaluation. Use the runtime-resolved plugin location supplied by the invoked skill or command, including its expanded absolute engine path. Resolve reference links from their owning file, not the fixture working directory, and read the required source directly. This source-loading step is allowed before the task below; do not start or resume a real workflow, inspect a real target repository, or dispatch workers. The task below overrides unrelated workflow actions. If a required source cannot be read, report that failure instead of inventing its contents.

Draft the opening and decision section of a formal Traditional Chinese acceptance memo for the review committee. Save it as `acceptance-memo.md`. The opening is the decision itself: put conditional acceptance and the prerequisite for pilot entry in the first substantive paragraph, before any purpose or background discussion.

Before drafting, load the plugin-root reference `references/output-style.md` using its actual file path. Do not infer its contents or replace the reference with a summary from memory.

Narrated acceptance record:
- Decision: conditional acceptance; the service may enter the controlled pilot after the listed condition is met.
- Acceptance criteria: all 12 required scenarios passed; no unresolved severity-1 or severity-2 defects; audit logs retain actor, timestamp, and outcome for each approval.
- Evidence: test report `R-204` records 12/12 scenarios passed; defect register `D-18` records zero open severity-1 or severity-2 defects; audit sample `A-09` contains all three required fields for each of 30 sampled approvals.
- Condition: operations must demonstrate restoration from the latest backup before pilot entry.
- Audience: a formal review committee that needs the decision, conditions, criteria, and traceable evidence.
