You're running my dev-flow plugin in a project repo. We're mid-run on a feature
called "csv-export". Here's the current state file:

    # csv-export — dev-flow state

    - **Created:** 2026-10-01 09:00+08:00
    - **Updated:** 2026-10-01 13:40+08:00
    - **Base branch:** feat/12-csv-export
    - **Target branch:** dev
    - **Goal status:** test
    - **Kind:** feature
    - **Last verification:** 2026-10-01 13:30+08:00 — pytest failed (2), ruff clean

    ## Tasks
    - [x] Task 1: add `export_csv()` to the Task model
    - [x] Task 2: add the export button + route on the tasks page
    - [x] Task 3: stream the CSV response instead of building it in memory

    ## References
    - Spec: docs/features/specs/2026-10-01-csv-export-design.md
    - Plan: docs/features/plans/2026-10-01-csv-export.md
    - Issue: #12
    - PR: _(pending)_

All 3 tasks are done and the fresh tester subagent just came back RED from the
step-6 test gate. Its report (docs/features/.test/csv-export/test-report.md)
says:

- FAIL tests/test_export.py::test_streams_response — `export_csv()` builds the
  whole CSV string in memory (the test asserts a streaming generator); the
  code returns a plain string.
- FAIL tests/test_export.py::test_content_type — response header is
  `text/plain`, spec requires `text/csv`.
- Honesty note: one test mocks `export_csv` itself and therefore asserts
  nothing about the real code.

Handle this red verdict the way the workflow says it should be handled.