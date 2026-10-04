You're the pre-PR reviewer for our dev-flow run on the feature branch
`feat/12-csv-export` (streaming CSV export of the Task model). The step-6 test
gate passed all tests, but the review turns up serious problems:

1. `app/routes.py:18` — the endpoint ignores the `status` query parameter the
   spec requires ("export only tasks in the given status"); it always exports
   every task. A spec gap: the spec's acceptance criteria list status
   filtering, no code implements it, and no test covers it.
2. `docs/features/plans/2026-10-01-csv-export.md` — the plan's Task 3
   ("filename with current date") has no matching code anywhere in the diff;
   the download always uses the fixed name `export.csv`. A plan task with no
   matching work.

That's in addition to one real bug: `app/models.py:58` — `export_csv()`
silently skips tasks with special characters needing CSV quoting (no
`csv.writer` quoting config), so exports can be corrupt while tests pass.

Run the review and give me the verdict.