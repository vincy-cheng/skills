# tests/checks/skill-contracts/08-task-outcomes.sh — task-outcome measurement contracts.
# Sourced by tests/checks/03-skill-contracts.sh; cwd is repo root.

outcome_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path
import sys
sys.path.insert(0, "tests/lib")
from sections import section

errors = []

def require(path, pattern, label, body=None, flags=re.I | re.S | re.M):
    try:
        text = body if body is not None else Path(path).read_text()
    except FileNotFoundError:
        errors.append(f"{path}:missing")
        return
    if not re.search(pattern, text, flags):
        errors.append(f"{path}:{label}")

# The shared reference exists with the four required sections.
reference = "references/task-outcomes.md"
for heading in ("Record format", "Collection procedure", "Comparison rules", "Recommendation format"):
    require(reference, rf"^## {re.escape(heading)}\s*$", f"missing-heading:{heading}")

# Step 11 records the outcome file in close-out.
new_feature = Path("skills/new-feature/SKILL.md")
try:
    skill_text = new_feature.read_text()
except FileNotFoundError:
    errors.append("skills/new-feature/SKILL.md:missing")
    skill_text = ""
step11 = section(skill_text, "Step 11 — Close-out") if skill_text else ""
if not step11:
    errors.append("new-feature:no-step-11-section")
else:
    require("new-feature", r"task-outcomes\.md", "step-11-no-task-outcomes-mention", step11)

# Step 5's Roles ask carries the pinned evidence tag (anti-loose anchor:
# a bare "evidence" pattern would false-pass on the existing
# "Test evidence:"/"Review evidence:" lines elsewhere in the file).
step5 = section(skill_text, "Step 5") if skill_text else ""
if not step5:
    errors.append("new-feature:no-step-5-section")
else:
    if not re.search(r"\[evidence:", step5):
        errors.append("new-feature:step-5-no-evidence-tag")

print("\n".join(errors))
PY
)
if [ -z "$outcome_errs" ]; then
  ok "task outcomes have a shared reference with pinned step-5/step-11 anchors"
else
  bad "task-outcome contract missing:$outcome_errs"
fi
