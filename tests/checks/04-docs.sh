# tests/checks/04-docs.sh — doc guards: spec-path convention, setup docs, plan mermaid blocks.
# sourced by tests/check.sh; cwd is repo root.

# spec path convention: file-shaped paths under docs/features/specs/ must be the
# design-doc or overview-doc pattern. Bare directory mentions are legitimate prose.
spec_bad=$(git grep -nE 'docs/features/specs/[^ )`]*\.md' -- 'skills/' 'commands/' 'README.md' 'AGENTS.md' \
  | $G -vE 'docs/features/specs/(YYYY-MM-DD-<feat-name>-(design|overview)|[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+-(design|overview))\.md' || true)
if [ -n "$spec_bad" ]; then
  bad "spec path deviates from convention:"; echo "$spec_bad"
else ok "spec paths consistent"; fi

# setup docs explain both hosts and point users to the repo Codex marketplace.
docs_errs=$(python3 -B - <<'PY'
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
    "INDEX Codex skill route": "skills/new-feature/SKILL.md" in index,
    "ARCHITECTURE portable manifest": ".codex-plugin/plugin.json" in architecture,
    "DEVOPS local marketplace setup": "marketplace add" in devops and "Plugins Directory" in devops,
}
for label, present in checks.items():
    if not present:
        print(label.replace(" ", "-").lower())
PY
)
if [ -z "$docs_errs" ]; then ok "dual-host setup documentation is linked and complete"; else bad "host setup docs incomplete:$docs_errs"; fi

# plan mermaid blocks: file lists must live inside node labels. The plan
# skill's flow-chart rule (fixed in #51) once showed 'Task N changes:'
# under its node; agents took it literally and emitted bare lines inside
# mermaid fences — invalid flowchart syntax (parse error in run #48).
# Structural check: any line inside a mermaid fence containing 'changes:'
# must be part of a quoted node label on the same line.
mermaid_errs=$(python3 -B - <<'PY'
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
if [ -z "$mermaid_errs" ]; then ok "plan mermaid blocks keep changes: inside node labels"; else bad "bare changes: lines in plan mermaid blocks:$mermaid_errs"; fi