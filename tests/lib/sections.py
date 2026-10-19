"""tests/lib/sections.py — shared section() helper for the python-based checks.

Imported via a sys.path preamble in the heredocs of tests/checks/*.sh
(run with `python3 -B` so no __pycache__ is written).
"""

import re


def section(text, heading):
    """Body of a `## <heading>` section (heading may carry a trailing title,
    e.g. `## Step 5 — Execute tasks (TDD)`), up to the next `## ` heading."""
    m = re.search(rf"^## {re.escape(heading)}\b[^\n]*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    return m.group(1) if m else ""