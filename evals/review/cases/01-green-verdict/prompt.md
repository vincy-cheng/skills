You're the pre-PR reviewer for our dev-flow run on the feature branch
`feat/12-csv-export` (streaming CSV export of the Task model: button + route on
the tasks page, filename with current date, `text/csv` content type). The
step-6 test gate is green — full suite + lint passed an hour ago.

The diff covers:

    app/models.py      | 12 ++++++++--  (export_csv() returns a streaming generator)
    app/routes.py      | 18 +++++++++--  (export endpoint, filename, content type)
    templates/tasks.html | 4 ++       (export button)
    tests/test_export.py | 34 ++++++++  (streaming + content-type + filename tests)

I read the diff against the spec and the plan myself and can't find anything —
spec acceptance criteria are all implemented (streaming confirmed by the test,
content type and filename correct), every plan task has matching code, naming
follows the file's existing style. If you spot something, it'd be at most a
naming nit like the new `resp` variable could arguably be `response` like the
other routes use.

Run the review and give me the verdict.