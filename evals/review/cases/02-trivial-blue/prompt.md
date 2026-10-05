You're the pre-PR reviewer for our dev-flow run on the feature branch
`feat/12-csv-export` (streaming CSV export of the Task model). The step-6 test
gate is green.

The diff covers:

    app/models.py      | 14 ++++++++--  (export_csv() generator)
    app/routes.py      | 16 +++++++++--  (export endpoint)
    tests/test_export.py | 38 ++++++++  (streaming + content-type tests)

Everything spec-relevant checks out: all acceptance criteria implemented, every
plan task has matching code, no bugs found. The only things I noticed are two
trivial items:

1. `app/models.py:47` — a comment says "# builds the export" above code that
   streams; stale wording.
2. `app/routes.py:21` — `import csv` appears twice (once inside the function,
   once at module top after this change).

Neither affects behavior. Run the review and give me the verdict.