# tests/checks/skill-contracts/07-context-efficiency.sh — context economy contracts.
# Sourced by tests/checks/03-skill-contracts.sh; cwd is repo root.

context_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path
import sys
sys.path.insert(0, "tests/lib")
from sections import section

errors = []

def require(path, pattern, label, body=None, flags=re.I | re.S):
    try:
        text = body if body is not None else Path(path).read_text()
    except FileNotFoundError:
        errors.append(f"{path}:missing")
        return
    if not re.search(pattern, text, flags):
        errors.append(f"{path}:{label}")

# New-feature owns the workflow-wide context reuse rule.
new_feature = Path("skills/new-feature/SKILL.md")
reuse_body = ""
try:
    reuse_body = section(new_feature.read_text(), "Context reuse")
except FileNotFoundError:
    errors.append("skills/new-feature/SKILL.md:missing")
if not reuse_body:
    errors.append("new-feature:no-context-reuse-section")
else:
    require("new-feature", r"only.{0,120}current step.{0,120}required (?:skills|references)", "current-step-scope", reuse_body)
    require("new-feature", r"reuse.{0,80}unchanged (?:guidance|skills|references)", "reuse", reuse_body)
    require("new-feature", r"(?:changed|modified) (?:file|guidance|reference)", "changed-reload", reuse_body)
    require("new-feature", r"unavailable", "unavailable-reload", reuse_body)
    require("new-feature", r"lost.{0,80}compaction|compaction.{0,80}lost", "compaction-reload", reuse_body)
    require("new-feature", r"version.{0,80}(?:unestablishable|cannot be established)", "version-reload", reuse_body)
    require("new-feature", r"cached.{0,240}(?:never|not).{0,120}(?:replace|substitute).{0,240}(?:live|authorization|evidence)", "hard-boundary", reuse_body)
    require("new-feature", r"small.{0,160}tightly.?coupled.{0,160}inline|inline.{0,160}small.{0,160}tightly.?coupled", "inline-recommendation", reuse_body)
    require("new-feature", r"existing.{0,160}role-selection", "existing-role-selection", reuse_body)
    require("new-feature", r"[Pp]reserve.{0,160}(?:roles|models|execution modes|saved choice)", "saved-choices", reuse_body)

# AGENTS.md carries a matching one-line rule without duplicating workflow content.
agents = Path("AGENTS.md")
require("AGENTS.md", r"[Cc]ontext reuse.{0,300}(?:only|current).{0,300}(?:relo|unavailable|changed|lost)", "context-reuse-rule")

# The shared dispatcher sources the context-efficiency fragment.
dispatcher = Path("tests/checks/03-skill-contracts.sh")
require("tests/checks/03-skill-contracts.sh", r"07-context-efficiency", "fragment-not-registered")

print("\n".join(errors))
PY
)
if [ -z "$context_errs" ]; then
  ok "context reuse follows bounded loading and fail-closed reload rules"
else
  bad "context reuse contract missing:$context_errs"
fi
