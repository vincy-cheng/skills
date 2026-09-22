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
# lines contrasting with docs/features/, saying "never", or naming a superpowers default
# are prohibition text, not artifact paths.
sp_hits=$(git grep -n 'docs/superpowers/' -- 'dev-flow/' | $G -vE 'docs/features/|never|default' || true)
if [ -n "$sp_hits" ]; then
  bad 2 "docs/superpowers/ path present (non-guard):"; echo "$sp_hits"
else ok 2 "no docs/superpowers/ artifact paths"; fi

# 3. No superpowers:brainstorming in tracked files (git grep skips gitignored docs/features/;
#    tests/check.sh excluded because it carries the pattern itself)
if git grep -q 'superpowers:brainstorming' -- ':!tests/check.sh'; then
  bad 3 "superpowers:brainstorming still referenced:"; git grep -n 'superpowers:brainstorming' -- ':!tests/check.sh'
else ok 3 "no superpowers:brainstorming references"; fi

# 4. No superpowers:test-driven-development in tracked files
if git grep -q 'superpowers:test-driven-development' -- ':!tests/check.sh'; then
  bad 4 "superpowers:test-driven-development still referenced:"; git grep -n 'superpowers:test-driven-development' -- ':!tests/check.sh'
else ok 4 "no superpowers:test-driven-development references"; fi

# 5. Spec path convention: file-shaped paths under docs/features/specs/ must be the
#    design-doc pattern. Bare directory mentions are legitimate prose.
spec_bad=$(git grep -nE 'docs/features/specs/[^ )`]*\.md' -- 'dev-flow/' 'README.md' 'AGENTS.md' \
  | $G -vE 'docs/features/specs/(YYYY-MM-DD-<feat-name>-design|[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+-design)\.md' || true)
if [ -n "$spec_bad" ]; then
  bad 5 "spec path deviates from convention:"; echo "$spec_bad"
else ok 5 "spec paths consistent"; fi

# 6. plugin.json valid JSON
if python3 -c "import json;json.load(open('dev-flow/.claude-plugin/plugin.json'))" 2>/dev/null; then
  ok 6 "plugin.json parses as JSON"
else bad 6 "plugin.json is not valid JSON"; fi

# 7. Invoke list maps to real skill files: every `dev-flow:<name>` mention has skills/<name>/SKILL.md with matching name:
inv_errs=""
for name in $($G -rhoE 'dev-flow:[a-z][a-z-]+' dev-flow/commands/ README.md AGENTS.md 2>/dev/null | sort -u | $G -oE '[a-z][a-z-]+$'); do
  sk="dev-flow/skills/$name/SKILL.md"
  [ -f "$sk" ] || inv_errs="$inv_errs dev-flow:$name:no-skill-file"
  [ -f "$sk" ] && ! $G -q "^name: $name" "$sk" && inv_errs="$inv_errs dev-flow:$name:name-mismatch"
done
[ -z "$inv_errs" ] && ok 7 "invocations map to real skills" || bad 7 "invocation errors:$inv_errs"

# 8. docs/features/ gitignored
if git check-ignore -q docs/features/; then ok 8 "docs/features/ gitignored"; else bad 8 "docs/features/ NOT gitignored"; fi

# 9. Plugin cache freshness vs repo (WARN only — never FAILs the suite)
CACHE="$HOME/.claude/plugins/cache/vincy-skills/dev-flow/0.1.0/skills"
if [ ! -d "$CACHE" ]; then
  wn 9 "plugin cache not found at $CACHE — evals will test nothing until the plugin is installed/refreshed"
else
  stale=""
  for f in dev-flow/skills/*/SKILL.md; do
    name=$(basename "$(dirname "$f")")
    [ -f "$CACHE/$name/SKILL.md" ] || { stale="$stale $name:missing-from-cache"; continue; }
    cmp -s "$f" "$CACHE/$name/SKILL.md" || stale="$stale $name:differs-from-cache"
  done
  [ -z "$stale" ] && echo "PASS 9: repo skills match installed cache" || wn 9 "cache stale (refresh plugin before running evals):$stale"
fi

echo "---"
echo "$pass passed, $fail failed, $warn warned"
[ "$fail" -eq 0 ]