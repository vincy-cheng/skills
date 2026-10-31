# tests/checks/07-hooks.sh — hooks-module structural guards (issue #76).
# sourced by tests/check.sh; cwd is repo root.
# Concept greps, not exact sentences (#70 lesson). The authoritative hooks
# gates are `claude plugin validate` / `claude plugin test` (host tools);
# this fragment only catches structural drift the bash suite can see.

HJ="hooks/hooks.json"
MOD="hooks/register.tsx"

# hooks.json exists, is valid JSON, and names an existing module
if [ -f "$HJ" ]; then
  hj_err=""
  python3 -c "import json,sys; json.load(open('$HJ'))" 2>/dev/null || hj_err="invalid-json"
  if [ -z "$hj_err" ]; then
    mod_ref=$(python3 -c "import json; print(json.load(open('$HJ'))['modules'][0])" 2>/dev/null || echo "")
    [ -n "$mod_ref" ] || hj_err="no-modules-entry"
    mod_path="hooks/${mod_ref#./}"
    [ -n "$mod_ref" ] && { [ -f "$mod_path" ] || hj_err="module-not-found:$mod_ref"; }
  fi
  if [ -z "$hj_err" ]; then ok "hooks.json valid, names an existing module"; else bad "hooks.json broken:$hj_err"; fi
else
  bad "hooks/hooks.json missing"
fi

# the hooks module carries the required event hooks (no command hooks: the
# band's [ Flow ] button is the pane's sole opener — no /flow command)
if [ -f "$MOD" ]; then
  mod_err=""
  for ev in "session.start" "turn.complete" "ui.render"; do
    $G -q "'$ev'" "$MOD" || mod_err="$mod_err missing:$ev"
  done
  # the pane's on-demand open is person-initiated (no session.start auto-open of the pane)
  $G -q "closeOnEscape" "$MOD" || mod_err="$mod_err missing:closeOnEscape"
  # no command surface: /flow was removed in favor of the band button
  $G -q "command.run" "$MOD" && mod_err="$mod_err banned:command.run-should-not-exist"
  if [ -z "$mod_err" ]; then ok "hooks module carries required event hooks"; else bad "hooks module:$mod_err"; fi
else
  bad "hooks module missing:$MOD"
fi

# the parser carries the gate-table status literals (single source within the module)
if [ -f "hooks/state.ts" ]; then
  st_err=""
  for status in fresh brainstorm spec planning issue execute test review doc-fix pr-review merged done; do
    $G -q "'$status'" hooks/state.ts || st_err="$st_err missing-status:$status"
  done
  # the timing source is the state file's field, not a store ledger
  $G -q "Status since" hooks/state.ts || st_err="$st_err missing:status-since-parse"
  if [ -z "$st_err" ]; then ok "state parser carries all lifecycle statuses + Status since"; else bad "state parser:$st_err"; fi
else
  bad "hooks/state.ts missing"
fi

# no .superpowers/ paths anywhere in hooks/
if $G -rqi "superpowers" hooks/ 2>/dev/null; then
  bad "superpowers path leaked into hooks/"
else
  ok "no superpowers paths in hooks/"
fi
