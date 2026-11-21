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

# Documentation ownership distinguishes in-flow build edits from standalone docs work.
commit_docs_errs=$(python3 -B - <<'PY'
from pathlib import Path

devops = Path("docs/agents/DEVOPS.md").read_text().lower()
index = Path("docs/agents/INDEX.md").read_text().lower()
checks = {
    "DEVOPS in-flow docs share the task commit": "in-flow known documentation" in devops and "committed with its task" in devops,
    "DEVOPS standalone docs use docs commits": "standalone doc updates" in devops and "separate `docs:` commits" in devops,
    "INDEX distinguishes both doc commit paths": "in-flow build doc fixes stay in their task commit" in index and "standalone doc updates use separate `docs:` commits" in index,
    "DEVOPS no blanket separate-docs rule": "doc updates ship as separate `docs:` commits from code" not in devops,
}
for label, present in checks.items():
    if not present:
        print(label.replace(" ", "-").lower())
PY
)
[ -z "$commit_docs_errs" ] && ok "in-flow and standalone documentation commit ownership is consistent" || bad "documentation commit ownership drift:$commit_docs_errs"

# Step 10 documentation must describe the readiness gate, version-bound
# evidence, result states, and the human-owned merge boundary.
pr_docs_errs=$(python3 -B - <<'PY'
from pathlib import Path

readme = Path("README.md").read_text().lower()
agents = Path("AGENTS.md").read_text().lower()
architecture = Path("docs/agents/ARCHITECTURE.md").read_text().lower()
checks = {
    "README step-10 transition": all(term in readme for term in (
        "pr readiness check", "pr-review → merged", "remote merge confirmation",
    )),
    "AGENTS evidence and manual merge boundary": all(term in agents for term in (
        "head sha", "base sha", "passed", "pending", "needs-fix", "never merges",
    )),
    "ARCHITECTURE state evidence": all(term in architecture for term in (
        "verification evidence", "pr check", "head sha", "base sha",
    )),
    "ARCHITECTURE version stays manifest-owned": "version `0.3.2`" not in architecture and "manifest owns the packaged version" in architecture,
}
for label, present in checks.items():
    if not present:
        print(label.replace(" ", "-").lower())
PY
)
if [ -z "$pr_docs_errs" ]; then ok "Step 10 readiness, evidence, and manual-merge documentation is consistent"; else bad "Step 10 documentation incomplete:$pr_docs_errs"; fi

# Public workflow maps put known documentation in build and describe step 8 as
# a consistency checkpoint while retaining the lifecycle.
flow_docs_errs=$(python3 -B - <<'PY'
from pathlib import Path

expected = {
    "README.md": ("four phases", "define", "build", "verify", "deliver", "documentation-consistency checkpoint", "pending or interrupted step 8 resumes at `doc-fix`"),
    "AGENTS.md": ("define / build / verify / deliver", "known documentation", "documentation-consistency checkpoint"),
    "docs/agents/INDEX.md": ("packaged version numbers are owned by", "user-facing phases are define / build / verify / deliver", "internal 11-step gate table"),
    "docs/agents/ARCHITECTURE.md": ("define (brainstorm", "build (execute TDD", "verify (test", "deliver (open/update PR", "documentation-consistency checkpoint", "pending or interrupted step 8 resumes at `doc-fix`"),
    "docs/agents/DEVOPS.md": ("four phases", "define", "build", "verify", "deliver", "documentation-consistency checkpoint", "pending or interrupted step 8 resumes at `doc-fix`"),
    "skills/new-feature/SKILL.md": ("four user-facing phases", "Define : brainstorm", "Build  : execute", "Verify : test", "Deliver: PR readiness", "documentation-consistency checkpoint"),
    "commands/new-feature.md": ("define (brainstorm", "build (execute, TDD, known documentation)", "verify (test", "deliver (PR"),
}
for rel, markers in expected.items():
    text = Path(rel).read_text().lower()
    for marker in markers:
        if marker.lower() not in text:
            print(f"{rel}:missing-{marker}")
command = Path("commands/new-feature.md").read_text()
frontmatter = command.split("---", 2)
description = frontmatter[1] if len(frontmatter) >= 3 else ""
if not all(phase in description.lower() for phase in ("define", "build", "verify", "deliver")):
    print("commands/new-feature.md:description-missing-four-phase-terms")
if "11 internal gated steps" not in description.lower():
    print("commands/new-feature.md:description-misframes-internal-steps")
if "ship (" in description.lower() or "plan (brainstorm" in description.lower():
    print("commands/new-feature.md:description-uses-retired-phase-labels")
PY
)
[ -z "$flow_docs_errs" ] && ok "workflow docs describe build-time documentation and the consistency checkpoint" || bad "build documentation docs drift:$flow_docs_errs"

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
