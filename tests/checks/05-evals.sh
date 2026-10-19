# tests/checks/05-evals.sh — eval case.yaml schema invariants.
# sourced by tests/check.sh; cwd is repo root.

# eval case.yaml schema invariants (silent-failure guards, learned the hard way):
#     a) turn/timeout settings must nest under `execution:` — top-level they are
#        silently ignored and runs die at the default 10 turns;
#     b) an explicit llm grader's `criteria:` is passed to the judge VERBATIM — a bare
#        file path is never resolved, so that grader scores on the string "graders/grader.md"
#        instead of the file (auto-discovered graders/*.md files do carry real content);
#     c) every referenced graders/*.md must exist (case dir first, then suite dir —
#        the legacy suites keep graders at suite level);
#     d) legacy fields (`grader:`, `extra_checks:`, `skill:`) are rejected by the
#        current CLI's strict schema — old-format cases can't run at all.
ev_errs=""
for f in evals/*/cases/*/case.yaml; do
  dir=$(dirname "$f"); suite=$(dirname "$(dirname "$dir")")
  $G -qE '^max_turns:|^timeout_seconds:' "$f" && ev_errs="$ev_errs $f:turns-top-level"
  if $G -qE '^ *criteria:' "$f" && $G -qE '^ *criteria: *[a-zA-Z0-9_./-]+\.md$' "$f"; then
    ev_errs="$ev_errs $f:criteria-is-bare-path"
  fi
  $G -qE '^(grader|extra_checks|skill):' "$f" && ev_errs="$ev_errs $f:legacy-schema"
  for g in $($G -oE 'graders/[a-zA-Z0-9_-]+\.md' "$f" | sort -u); do
    { [ -f "$dir/$g" ] || [ -f "$suite/$g" ]; } || ev_errs="$ev_errs $f:missing-$g"
  done
done
[ -z "$ev_errs" ] && ok "eval case.yaml schema sound" || bad "eval schema errors:$ev_errs"