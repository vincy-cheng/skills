# tests/checks/02-packaging.sh — self-containment + layout + manifests.
# sourced by tests/check.sh; cwd is repo root.
# Pathspec note: the two tree-wide greps (superpowers:*, dev-flow/ literals)
# self-exclude via ':!tests/' — the whole tests/ tree, not check.sh by name;
# after the split the patterns live here and in sibling fragments.

# no docs/superpowers/ artifact paths in skills/ or commands/. Guard mentions are legitimate:
# each mention is exempt only if the 40 chars BEFORE it carry a guard cue (never /
# default / contrast with docs/features/) — context-scoped, not whole-line, so a real
# artifact path elsewhere on a guard-word line is still caught. evals/ is
# excluded — eval fixtures quote forbidden paths as grading criteria by design.
sp_hits=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  ung=$(printf '%s\n' "$line" | $G -oE '.{0,40}docs/superpowers/' | $G -cvE 'never|default|docs/features/' || true)
  [ "${ung:-0}" -gt 0 ] && sp_hits="$sp_hits$line
"
done <<EOF
$(git grep -n 'docs/superpowers/' -- 'skills/' 'commands/' ':!evals/' || true)
EOF
if [ -n "$sp_hits" ]; then
  bad "docs/superpowers/ path present (non-guard):"; printf '%s\n' "$sp_hits"
else ok "no docs/superpowers/ artifact paths"; fi

# no superpowers:* references in tracked files outside the plugin dirs (git grep skips
# gitignored docs/features/; tests/ excluded — the suite itself carries the pattern;
# README/AGENTS.md excluded — intentional inspiration-credit prose is legitimate)
if git grep -qE 'superpowers:[a-z-]+' -- ':!tests/' ':!README.md' ':!AGENTS.md' 2>/dev/null; then
  bad "superpowers:* reference outside dev-flow:"; git grep -nE 'superpowers:[a-z-]+' -- ':!tests/' ':!README.md' ':!AGENTS.md'
else ok "no superpowers:* references outside dev-flow"; fi

# no superpowers:* skill invocations in tracked dev-flow files (evals excluded —
# fixtures quote forbidden invocations as grading criteria; tests/ excluded —
# the suite carries the pattern itself). Guards the dependency creeping back.
if git grep -qE 'superpowers:[a-z-]+' -- 'skills/' 'commands/' ':!evals/' ':!tests/' 2>/dev/null; then
  bad "superpowers:* invocation still referenced:"; git grep -nE 'superpowers:[a-z-]+' -- 'skills/' 'commands/' ':!evals/' ':!tests/'
else ok "no superpowers:* invocations in dev-flow"; fi

# unwrapped layout (plugin-layout run): the plugin components live at the repo
# root, so dev-flow/ path literals must stay gone. Allowlist is built into the
# pattern: the leading [^.] class never matches .dev-flow/ (the branch-config
# path), and dev-flow:<name> invoke names contain no dev-flow/ path. Concept
# grep on path patterns, never sentences; tests/ excluded (carries the pattern).
lit_hits=$(git grep -nE '(^|[^.a-zA-Z0-9_-])dev-flow/(skills|commands|evals|plugin\.json|\.claude-plugin)' -- ':!tests/' || true)
if [ -n "$lit_hits" ]; then
  bad "dev-flow/ path literal still present (unwrapped layout):"; printf '%s\n' "$lit_hits"
else ok "no dev-flow/ path literals (unwrapped layout)"; fi

# plugin.json valid JSON + fully self-contained: no peerDependencies key, no
# superpowers:* invocations anywhere in dev-flow (guards the dependency creeping back).
if python3 -c "import json;json.load(open('.claude-plugin/plugin.json'))" 2>/dev/null; then
  if python3 -c "import json;import sys;sys.exit(0 if 'peerDependencies' in json.load(open('.claude-plugin/plugin.json')) else 1)" 2>/dev/null; then
    bad "plugin.json still declares peerDependencies"
  else
    ok "plugin.json valid; no peerDependencies"
  fi
else bad "plugin.json is not valid JSON"; fi

# Codex portable manifest and repo marketplace point to the shared dev-flow plugin.
codex_errs=$(python3 - <<'PY'
import json
from pathlib import Path

portable_path = Path(".codex-plugin/plugin.json")
marketplace_path = Path(".agents/plugins/marketplace.json")
claude_path = Path(".claude-plugin/plugin.json")
try:
    portable = json.loads(portable_path.read_text())
    marketplace = json.loads(marketplace_path.read_text())
    claude = json.loads(claude_path.read_text())
except (OSError, json.JSONDecodeError) as error:
    print(f"invalid-or-missing-json:{error}")
else:
    if portable.get("name") != "dev-flow":
        print("portable-name-mismatch")
    if portable.get("skills") != "./skills/":
        print("codex-manifest-skills-pointer-missing")
    if portable.get("references") != "./references/":
        print("codex-manifest-references-pointer-missing")
    if not Path("references/model-routing.md").is_file():
        print("references/model-routing.md:missing")
    if portable.get("version") != claude.get("version"):
        print("portable-version-mismatch")
    plugin = next((item for item in marketplace.get("plugins", []) if item.get("name") == "dev-flow"), None)
    if plugin is None:
        print("marketplace-plugin-missing")
    else:
        if plugin.get("source", {}).get("source") != "local" or plugin.get("source", {}).get("path") != "./":
            print("marketplace-source-mismatch")
        if plugin.get("policy", {}).get("installation") != "AVAILABLE":
            print("marketplace-installation-policy-missing")
        if plugin.get("policy", {}).get("authentication") != "ON_INSTALL":
            print("marketplace-authentication-policy-missing")
    try:
        claude_marketplace = json.loads(Path(".claude-plugin/marketplace.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        print(f"invalid-or-missing-json:{error}")
    else:
        entry = next((item for item in claude_marketplace.get("plugins", []) if item.get("name") == "dev-flow"), None)
        if entry is None:
            print("claude-marketplace-plugin-missing")
        elif entry.get("source") != "./":
            print("claude-marketplace-source-mismatch")
        elif entry.get("version") != claude.get("version"):
            print("claude-marketplace-version-mismatch")
PY
)
if [ -z "$codex_errs" ]; then ok "Codex manifest and marketplace wiring are valid"; else bad "Codex package metadata broken:$codex_errs"; fi