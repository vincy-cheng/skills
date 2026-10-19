# tests/checks/06-local.sh — local-environment guards: docs/features/ gitignore + plugin cache freshness.
# sourced by tests/check.sh; cwd is repo root.

# docs/features/ gitignored
if git check-ignore -q docs/features/; then ok "docs/features/ gitignored"; else bad "docs/features/ NOT gitignored"; fi

echo "---"
PLUGIN_VERSION=$(python3 -c "import json;print(json.load(open('.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo unknown)
CACHE="$HOME/.claude/plugins/cache/vincy-skills/dev-flow/$PLUGIN_VERSION/skills"
if [ ! -d "$CACHE" ]; then
  wn "plugin cache not found at $CACHE — evals will test nothing until the plugin is installed/refreshed"
else
  stale=""
  for f in skills/*/SKILL.md; do
    name=$(basename "$(dirname "$f")")
    [ -f "$CACHE/$name/SKILL.md" ] || { stale="$stale $name:missing-from-cache"; continue; }
    cmp -s "$f" "$CACHE/$name/SKILL.md" || stale="$stale $name:differs-from-cache"
  done
  [ -z "$stale" ] && ok "repo skills match installed cache" || wn "cache stale (refresh plugin before running evals):$stale"
fi