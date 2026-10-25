# tests/checks/01-structure.sh — frontmatter + invoke wiring.
# sourced by tests/check.sh; cwd is repo root.

# frontmatter: every SKILL.md has `---` line 1 and a `name:`; every command .md has `---` and `description:`
fm_errs=""
for f in skills/*/SKILL.md; do
  head -1 "$f" | $G -q '^---' || fm_errs="$fm_errs $f:no-fence"
  $G -q '^name:' "$f" || fm_errs="$fm_errs $f:no-name"
done
for f in commands/*.md; do
  head -1 "$f" | $G -q '^---' || fm_errs="$fm_errs $f:no-fence"
  $G -q '^description:' "$f" || fm_errs="$fm_errs $f:no-description"
done
[ -z "$fm_errs" ] && ok "frontmatter well-formed" || bad "frontmatter broken:$fm_errs"

# invoke list maps to real skill files: every `dev-flow:<name>` mention has skills/<name>/SKILL.md with matching name:
inv_errs=""
for name in $($G -rhoE 'dev-flow:[a-z][a-z-]+' commands/ README.md AGENTS.md 2>/dev/null | sort -u | $G -oE '[a-z][a-z-]+$'); do
  sk="skills/$name/SKILL.md"
  [ -f "$sk" ] || inv_errs="$inv_errs dev-flow:$name:no-skill-file"
  [ -f "$sk" ] && ! $G -q "^name: $name" "$sk" && inv_errs="$inv_errs dev-flow:$name:name-mismatch"
done
[ -z "$inv_errs" ] && ok "invocations map to real skills" || bad "invocation errors:$inv_errs"