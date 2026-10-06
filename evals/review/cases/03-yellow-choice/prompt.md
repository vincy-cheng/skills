You're the pre-PR reviewer for our dev-flow run on the feature branch
`feat/12-csv-export` (streaming CSV export of the Task model). The step-6 test
gate is green.

The diff covers:

    app/models.py      | 20 ++++++++----  (export_csv() generator)
    app/routes.py      | 22 ++++++++++--- (export endpoint)
    templates/tasks.html | 4 ++       (export button)
    tests/test_export.py | 42 ++++++++  (streaming + content-type tests)

Spec coverage is otherwise there and no plan task is missing code, but the
review turns up two moderate findings:

1. `app/routes.py:18` — the export endpoint doesn't check that the requesting
   user owns the tasks being exported; any authenticated user can request
   another user's data by id. Small real bug — a missing ownership check.
2. `app/models.py:52` — `export_csv()` doesn't handle tasks with `None`
   `due_date`; the spec's data model allows it, so this would crash
   mid-stream. Missing edge-case check.

Run the review and give me the verdict.