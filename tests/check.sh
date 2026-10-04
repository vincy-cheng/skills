#!/usr/bin/env bash
# tests/check.sh — consistency invariants for this Markdown-only plugin repo.
# Zero-token suite run by dev-flow step 6. exit 0 = green, 1 = any FAIL.
set -u
cd "$(dirname "$0")/.."   # run from repo root regardless of caller cwd
G=/usr/bin/grep           # absolute path: bypasses the rtk hook that rewrites bare grep

pass=0; fail=0; warn=0
ok()  { pass=$((pass+1)); echo "PASS $1: $2"; }
bad() { fail=$((fail+1)); echo "FAIL $1: $2"; }
wn()  { warn=$((warn+1)); echo "WARN $1: $2"; }

# 1. Frontmatter: every SKILL.md has `---` line 1 and a `name:`; every command .md has `---` and `description:`
fm_errs=""
for f in dev-flow/skills/*/SKILL.md; do
  head -1 "$f" | $G -q '^---' || fm_errs="$fm_errs $f:no-fence"
  $G -q '^name:' "$f" || fm_errs="$fm_errs $f:no-name"
done
for f in dev-flow/commands/*.md; do
  head -1 "$f" | $G -q '^---' || fm_errs="$fm_errs $f:no-fence"
  $G -q '^description:' "$f" || fm_errs="$fm_errs $f:no-description"
done
[ -z "$fm_errs" ] && ok 1 "frontmatter well-formed" || bad 1 "frontmatter broken:$fm_errs"

# 2. No docs/superpowers/ artifact paths in dev-flow/. Guard mentions are legitimate:
# each mention is exempt only if the 40 chars BEFORE it carry a guard cue (never /
# default / contrast with docs/features/) — context-scoped, not whole-line, so a real
# artifact path elsewhere on a guard-word line is still caught. dev-flow/evals/ is
# excluded — eval fixtures quote forbidden paths as grading criteria by design.
sp_hits=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  ung=$(printf '%s\n' "$line" | $G -oE '.{0,40}docs/superpowers/' | $G -cvE 'never|default|docs/features/' || true)
  [ "${ung:-0}" -gt 0 ] && sp_hits="$sp_hits$line
"
done <<EOF
$(git grep -n 'docs/superpowers/' -- 'dev-flow/' ':!dev-flow/evals/' || true)
EOF
if [ -n "$sp_hits" ]; then
  bad 2 "docs/superpowers/ path present (non-guard):"; printf '%s\n' "$sp_hits"
else ok 2 "no docs/superpowers/ artifact paths"; fi

# 3. No superpowers:* references in tracked files outside dev-flow/ (git grep skips
#    gitignored docs/features/; tests/check.sh excluded — it carries the pattern itself;
#    README/AGENTS.md excluded — intentional inspiration-credit prose is legitimate)
if git grep -qE 'superpowers:[a-z-]+' -- ':!tests/check.sh' ':!README.md' ':!AGENTS.md' 2>/dev/null; then
  bad 3 "superpowers:* reference outside dev-flow:"; git grep -nE 'superpowers:[a-z-]+' -- ':!tests/check.sh' ':!README.md' ':!AGENTS.md'
else ok 3 "no superpowers:* references outside dev-flow"; fi

# 5. Spec path convention: file-shaped paths under docs/features/specs/ must be the
#    design-doc or overview-doc pattern. Bare directory mentions are legitimate prose.
spec_bad=$(git grep -nE 'docs/features/specs/[^ )`]*\.md' -- 'dev-flow/' 'README.md' 'AGENTS.md' \
  | $G -vE 'docs/features/specs/(YYYY-MM-DD-<feat-name>-(design|overview)|[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+-(design|overview))\.md' || true)
if [ -n "$spec_bad" ]; then
  bad 5 "spec path deviates from convention:"; echo "$spec_bad"
else ok 5 "spec paths consistent"; fi

# 6. plugin.json valid JSON + fully self-contained: no peerDependencies key, no
#    superpowers:* invocations anywhere in dev-flow (guards the dependency creeping back).
if python3 -c "import json;json.load(open('dev-flow/.claude-plugin/plugin.json'))" 2>/dev/null; then
  if python3 -c "import json;import sys;sys.exit(0 if 'peerDependencies' in json.load(open('dev-flow/.claude-plugin/plugin.json')) else 1)" 2>/dev/null; then
    bad 6 "plugin.json still declares peerDependencies"
  else
    ok 6 "plugin.json valid; no peerDependencies"
  fi
else bad 6 "plugin.json is not valid JSON"; fi

# 7. Invoke list maps to real skill files: every `dev-flow:<name>` mention has skills/<name>/SKILL.md with matching name:
inv_errs=""
for name in $($G -rhoE 'dev-flow:[a-z][a-z-]+' dev-flow/commands/ README.md AGENTS.md 2>/dev/null | sort -u | $G -oE '[a-z][a-z-]+$'); do
  sk="dev-flow/skills/$name/SKILL.md"
  [ -f "$sk" ] || inv_errs="$inv_errs dev-flow:$name:no-skill-file"
  [ -f "$sk" ] && ! $G -q "^name: $name" "$sk" && inv_errs="$inv_errs dev-flow:$name:name-mismatch"
done
[ -z "$inv_errs" ] && ok 7 "invocations map to real skills" || bad 7 "invocation errors:$inv_errs"

# 8. plan skill exists with correct frontmatter and its contract-first mandates
PLAN_SKILL="dev-flow/skills/plan/SKILL.md"
plan_errs=""
if [ ! -f "$PLAN_SKILL" ]; then
  plan_errs=" $PLAN_SKILL:missing"
else
  $G -q '^name: plan' "$PLAN_SKILL" || plan_errs="$plan_errs plan:no-name"
  $G -q '## Flow Chart' "$PLAN_SKILL" || plan_errs="$plan_errs plan:no-flow-chart-mandate"
  $G -q 'docs/features/plans/' "$PLAN_SKILL" || plan_errs="$plan_errs plan:no-save-path"
fi
[ -z "$plan_errs" ] && ok 8 "plan skill present with contract-first mandates" || bad 8 "plan skill broken:$plan_errs"

# 9. No superpowers:* skill invocations in tracked dev-flow files (evals excluded —
#    fixtures quote forbidden invocations as grading criteria; check.sh excluded —
#    it carries the pattern itself). Guards the dependency creeping back.
if git grep -qE 'superpowers:[a-z-]+' -- 'dev-flow/' ':!dev-flow/evals/' ':!tests/check.sh' 2>/dev/null; then
  bad 9 "superpowers:* invocation still referenced:"; git grep -nE 'superpowers:[a-z-]+' -- 'dev-flow/' ':!dev-flow/evals/' ':!tests/check.sh'
else ok 9 "no superpowers:* invocations in dev-flow"; fi

# 10. docs/features/ gitignored
if git check-ignore -q docs/features/; then ok 10 "docs/features/ gitignored"; else bad 10 "docs/features/ NOT gitignored"; fi

# 13. Codex portable manifest and repo marketplace point to the shared dev-flow plugin.
codex_errs=$(python3 - <<'PY'
import json
from pathlib import Path

portable_path = Path("dev-flow/plugin.json")
marketplace_path = Path(".agents/plugins/marketplace.json")
claude_path = Path("dev-flow/.claude-plugin/plugin.json")
try:
    portable = json.loads(portable_path.read_text())
    marketplace = json.loads(marketplace_path.read_text())
    claude = json.loads(claude_path.read_text())
except (OSError, json.JSONDecodeError) as error:
    print(f"invalid-or-missing-json:{error}")
else:
    if portable.get("name") != "dev-flow":
        print("portable-name-mismatch")
    if portable.get("version") != claude.get("version"):
        print("portable-version-mismatch")
    plugin = next((item for item in marketplace.get("plugins", []) if item.get("name") == "dev-flow"), None)
    if plugin is None:
        print("marketplace-plugin-missing")
    else:
        if plugin.get("source", {}).get("source") != "local" or plugin.get("source", {}).get("path") != "./dev-flow":
            print("marketplace-source-mismatch")
        if plugin.get("policy", {}).get("installation") != "AVAILABLE":
            print("marketplace-installation-policy-missing")
        if plugin.get("policy", {}).get("authentication") != "ON_INSTALL":
            print("marketplace-authentication-policy-missing")
PY
)
if [ -z "$codex_errs" ]; then ok 13 "Codex manifest and marketplace wiring are valid"; else bad 13 "Codex package metadata broken:$codex_errs"; fi

# 14. Codex has a new-feature skill that carries the full gated workflow.
skill_errs=$(python3 - <<'PY'
import re
from pathlib import Path

path = Path("dev-flow/skills/new-feature/SKILL.md")
try:
    text = path.read_text()
except FileNotFoundError:
    print("skill-missing")
except OSError as error:
    print(f"skill-unreadable:{error}")
else:
    header = text.split("---", 2)
    metadata = header[1] if len(header) == 3 and header[0] == "" else ""
    if not re.search(r"^name: new-feature$", metadata, re.M):
        print("name-missing")
    if not re.search(r"^description:\s*\S", metadata, re.M):
        print("description-missing")
    if re.findall(r"^## Step (\d+)\b", text, re.M) != [str(n) for n in range(1, 12)]:
        print("step-sequence-incomplete")
    for marker in ("## The hard gate", "## Resume", "## Commit guard", "| Step | Requires incoming | Sets |"):
        if marker not in text:
            print("missing-" + marker.strip("# |:").replace(" ", "-").lower())
    required = {"brainstorm", "plan", "execute-tasks", "tdd", "test", "review", "doc-fix", "open-pr", "create-github-issue", "commit"}
    found = set(re.findall(r"dev-flow:([a-z][a-z-]+)", text))
    if required - found:
        print("missing-skill-routes:" + ",".join(sorted(required - found)))
PY
)
if [ -z "$skill_errs" ]; then ok 14 "Codex new-feature skill retains the gated workflow"; else bad 14 "new-feature skill broken:$skill_errs"; fi

# 15. Setup docs explain both hosts and point users to the repo Codex marketplace.
docs_errs=$(python3 - <<'PY'
from pathlib import Path

docs = {}
missing = []
for key, rel in (
    ("readme", "README.md"),
    ("agents", "AGENTS.md"),
    ("index", "docs/agents/INDEX.md"),
    ("architecture", "docs/agents/ARCHITECTURE.md"),
    ("devops", "docs/agents/DEVOPS.md"),
):
    try:
        docs[key] = Path(rel).read_text()
    except FileNotFoundError:
        missing.append(rel)
    except OSError as error:
        missing.append(f"{rel}:{error}")
if missing:
    print("missing-docs:" + ",".join(missing))
readme = docs.get("readme", "")
agents = docs.get("agents", "")
index = docs.get("index", "")
architecture = docs.get("architecture", "")
devops = docs.get("devops", "")
checks = {
    "README Codex setup": "codex plugin marketplace add" in readme,
    "README Codex skill invocation": "$dev-flow:new-feature" in readme,
    "README Claude command retained": "/new-feature" in readme,
    "AGENTS dual-host packaging": "Codex" in agents and "Claude Code" in agents,
    "INDEX Codex skill route": "dev-flow/skills/new-feature/SKILL.md" in index,
    "ARCHITECTURE portable manifest": "dev-flow/plugin.json" in architecture,
    "DEVOPS local marketplace setup": "marketplace add" in devops and "Plugins Directory" in devops,
}
for label, present in checks.items():
    if not present:
        print(label.replace(" ", "-").lower())
PY
)
if [ -z "$docs_errs" ]; then ok 15 "dual-host setup documentation is linked and complete"; else bad 15 "host setup docs incomplete:$docs_errs"; fi

# 16. Plan mermaid blocks: file lists must live inside node labels. The plan
#     skill's flow-chart rule (fixed in #51) once showed 'Task N changes:'
#     under its node; agents took it literally and emitted bare lines inside
#     mermaid fences — invalid flowchart syntax (parse error in run #48).
#     Structural check: any line inside a mermaid fence containing 'changes:'
#     must be part of a quoted node label on the same line.
mermaid_errs=$(python3 - <<'PY'
import re
from pathlib import Path

FENCE = chr(96) * 3  # backtick triplet, kept out of the script to stay bash-safe

for path in sorted(Path("docs/features/plans").glob("*.md")):
    in_fence = False
    for lineno, line in enumerate(path.read_text().splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith(FENCE + "mermaid"):
            in_fence = True
            continue
        if in_fence and stripped == FENCE:
            in_fence = False
            continue
        if not in_fence or "changes:" not in line:
            continue
        # a quoted node label containing changes: on the same line is valid
        if re.search(r'"[^"]*changes:[^"]*"', line):
            continue
        print(f"{path.name}:{lineno}:bare-changes-in-mermaid")
PY
)
if [ -z "$mermaid_errs" ]; then ok 16 "plan mermaid blocks keep changes: inside node labels"; else bad 16 "bare changes: lines in plan mermaid blocks:$mermaid_errs"; fi

# 12. Eval case.yaml schema invariants (silent-failure guards, learned the hard way):
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
for f in dev-flow/evals/*/cases/*/case.yaml; do
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
[ -z "$ev_errs" ] && ok 12 "eval case.yaml schema sound" || bad 12 "eval schema errors:$ev_errs"

echo "---"
PLUGIN_VERSION=$(python3 -c "import json;print(json.load(open('dev-flow/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo unknown)
CACHE="$HOME/.claude/plugins/cache/vincy-skills/dev-flow/$PLUGIN_VERSION/skills"
if [ ! -d "$CACHE" ]; then
  wn 11 "plugin cache not found at $CACHE — evals will test nothing until the plugin is installed/refreshed"
else
  stale=""
  for f in dev-flow/skills/*/SKILL.md; do
    name=$(basename "$(dirname "$f")")
    [ -f "$CACHE/$name/SKILL.md" ] || { stale="$stale $name:missing-from-cache"; continue; }
    cmp -s "$f" "$CACHE/$name/SKILL.md" || stale="$stale $name:differs-from-cache"
  done
  [ -z "$stale" ] && ok 11 "repo skills match installed cache" || wn 11 "cache stale (refresh plugin before running evals):$stale"
fi

echo "---"
echo "$pass passed, $fail failed, $warn warned"
[ "$fail" -eq 0 ]
