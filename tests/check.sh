#!/usr/bin/env bash
# tests/check.sh — consistency invariants for this Markdown-only plugin repo.
# Thin runner: sources lib helpers then the concern-grouped fragments in order.
# Zero-token suite run by dev-flow step 6. exit 0 = green, 1 = any FAIL.
set -u
cd "$(dirname "$0")/.."   # run from repo root regardless of caller cwd
source tests/lib/helpers.sh

# Explicit ordered source list — the auditable manifest of the suite.
# A listed fragment that does not exist aborts the run (fail loud, not silent skip).
for frag in 01-structure 02-packaging 03-skill-contracts 04-docs 05-evals 06-local 07-hooks; do
  [ -f "tests/checks/$frag.sh" ] || { echo "FAIL: missing fragment tests/checks/$frag.sh"; exit 1; }
  source "tests/checks/$frag.sh"
done

echo "---"
echo "$pass passed, $fail failed, $warn warned"
[ "$fail" -eq 0 ]