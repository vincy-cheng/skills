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
    require("new-feature", r"when (?:it|a (?:file|guidance|reference)) changes", "changed-reload", reuse_body)
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

boundary_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

errors = []

def require(path, pattern, label, flags=re.I | re.S | re.M):
    try:
        body = Path(path).read_text()
    except FileNotFoundError:
        errors.append(f"{path}:missing")
        return
    if (flags := re.I | re.S | re.M) and not re.search(pattern, body, flags):
        errors.append(f"{path}:{label}")

# One isolated-brief boundary, not a second boundary copied into each chain.
require("references/model-routing.md", r"^## Isolated brief boundary", "boundary-heading", )
routing = Path("references/model-routing.md").read_text()
for marker in (
    r"task\b", r"constraints?", r"relevant paths", r"exact interfaces from earlier tasks",
    r"output-style contents", r"report contract",
    r"no unrelated conversation history|without unrelated conversation history",
):
    if not re.search(marker, routing, re.I | re.S):
        errors.append(f"model-routing:{marker}-missing")
if not re.search(r"one complete copy.{0,160}brief", routing, re.I | re.S):
    errors.append("model-routing:one-copy-per-brief")
if not re.search(r"[Dd]o not repeat.{0,160}shared guidance|shared guidance.{0,160}once|no duplicate shared guidance", routing, re.I | re.S):
    errors.append("model-routing:deduplicate-shared-guidance")
if not re.search(r"exit status.{0,500}failure details.{0,500}required evidence.{0,500}(?:usable|full logs)", routing, re.I | re.S):
    errors.append("model-routing:transport-safeguards")
if not re.search(r"[Ff]ull (?:logs|findings).{0,160}local (?:report|artifact)", routing, re.I | re.S):
    errors.append("model-routing:local-full-report")
if not re.search(r"orchestrator.{0,200}(?:read|reads).{0,200}report", routing, re.I | re.S):
    errors.append("model-routing:orchestrator-report-read")
if not re.search(r"decision-relevant findings?", routing, re.I | re.S):
    errors.append("model-routing:decision-findings")
if not re.search(r"stale evidence.{0,400}relevant uncommitted path.{0,400}missing report.{0,400}unavailable reference.{0,400}failed dispatch", routing, re.I | re.S):
    errors.append("model-routing:blocking-rules")
if not re.search(r"same evidence type.{0,200}required producer", routing, re.I | re.S):
    errors.append("model-routing:evidence-type-producer-reuse")
if not re.search(r"implementation evidence.{0,400}tester evidence.{0,400}separate|separate.{0,400}implementation evidence.{0,400}tester evidence", routing, re.I | re.S):
    errors.append("model-routing:implementation-tester-separation")
if not re.search(r"revalidat.{0,240}(?:code|requirements|evidence identity).{0,240}(?:changes?|stale)", routing, re.I | re.S):
    errors.append("model-routing:revalidation")
if not re.search(r"[Rr]epository.{0,240}HEAD SHA.{0,240}Base ref.{0,240}Base SHA.{0,240}report path.{0,240}(?:relevant )?working-tree state", routing, re.I | re.S):
    errors.append("model-routing:evidence-tuple")

# Execution keeps small probes small and separates task completion from full gates.
require("skills/execute-tasks/SKILL.md", r"smallest targeted.{0,120}(?:RED|GREEN|check|test)", "targeted-implementation-checks")
require("skills/execute-tasks/SKILL.md", r"task-completion checks?", "task-completion-checks")
require("skills/execute-tasks/SKILL.md", r"after-all-tasks.{0,500}full test.{0,200}lint", "after-all-full-suite")

# Step 6 remains the only independent full-suite gate.
require("skills/test/SKILL.md", r"only independent full-suite gate", "independent-full-suite-gate")

# Review is not a rerun of the test gate, and its concise return must not hide findings.
require("skills/review/SKILL.md", r"orchestrator.{0,200}(?:read|reads).{0,200}(?:review )?report", "review-report-read")
require("skills/review/SKILL.md", r"decision-relevant findings?", "decision-findings")

# The three dispatching skills point to the shared boundary instead of copying it.
for path in (
    "skills/execute-tasks/SKILL.md",
    "skills/test/SKILL.md",
    "skills/review/SKILL.md",
):
    require(path, r"[Ii]solated[- ](?:worker |worker )?brief boundary", "shared-boundary-pointer")

# Count one canonical copy of each deduplicated dispatch-chain phrase.
chain_files = ("references/model-routing.md", "skills/execute-tasks/SKILL.md", "skills/test/SKILL.md", "skills/review/SKILL.md")
for phrase in (
    "exact interfaces from earlier tasks",
    "no unrelated conversation history",
    "one complete copy",
):
    occurrences = sum(Path(path).read_text().lower().count(phrase) for path in chain_files)
    if occurrences != 1:
        errors.append(f"dispatch-chain:{phrase}:{occurrences}-occurrences")

print("\n".join(errors))

PY
)
if [ -z "$boundary_errs" ]; then
  ok "isolated dispatch keeps complete bounded briefs and evidence-bound validation"
else
  bad "isolated dispatch contract missing:$boundary_errs"
fi

eval_errs=''
required_eval_files=(
  "evals/context-efficiency/cases/01-reuse-and-reload/case.yaml"
  "evals/context-efficiency/cases/01-reuse-and-reload/prompt.md"
  "evals/context-efficiency/cases/01-reuse-and-reload/graders/grader.md"
  "evals/context-efficiency/cases/02-isolated-brief/case.yaml"
  "evals/context-efficiency/cases/02-isolated-brief/prompt.md"
  "evals/context-efficiency/cases/02-isolated-brief/graders/grader.md"
  "evals/context-efficiency/cases/03-evidence-boundary/case.yaml"
  "evals/context-efficiency/cases/03-evidence-boundary/prompt.md"
  "evals/context-efficiency/cases/03-evidence-boundary/graders/grader.md"
)
for eval_file in "${required_eval_files[@]}"; do
  [ -s "$eval_file" ] || eval_errs="$eval_errs $eval_file:missing-or-empty"
done
grep -q '`context-efficiency`' evals/README.md || eval_errs="$eval_errs evals/README.md:context-efficiency-suite-not-listed"
# The bounded comparison is run-local evidence under gitignored docs/features/.
# Keep the repository suite portable across clean checkouts.
if [ -z "$eval_errs" ]; then
  ok "context-efficiency evals are present; bounded comparison evidence stays local"
else
  bad "context-efficiency eval evidence missing:$eval_errs"
fi
