# tests/checks/skill-contracts/05-status-prose-and-review-gates.sh — status, prose, and review-gate contract checks.
# Sourced by tests/checks/03-skill-contracts.sh; cwd is repo root.

# gate26: Status-since timing protocol (issue #76) — the status transition is
# three writes in one breath (Goal status + index + Status since), defined once
# in new-feature's gate rule and template, and cited from every skill that
# itself flips Goal status (create-github-issue, execute-tasks, test's
# red-loop rewind, doc-fix). Concept grep only, never exact sentences (#38);
# a flipping skill that never names the third write fails.
gate26_errs=$(python3 -B - <<'PY'
import re
import sys
sys.path.insert(0, "tests/lib")
from pathlib import Path

nf_path = Path("skills/new-feature/SKILL.md")
try:
    nf = nf_path.read_text()
except FileNotFoundError:
    print("skills/new-feature/SKILL.md:missing")
else:
    # the three-writes protocol in the gate rule (Step 0 / gate-check area)
    gate_rule = nf
    if not re.search(r"Status since", gate_rule):
        print("new-feature:gate-rule-no-status-since")
    if not re.search(r"three writes", gate_rule):
        print("new-feature:gate-rule-no-three-writes")
    # the template carries the field
    if not re.search(r"\*\*Status since:\*\*", nf):
        print("new-feature:state-template-missing-status-since")
    # field rule names what it is for (timing source, set on status change)
    if not re.search(r"Status since.*timestamp|timestamp.*Status since", nf, re.S):
        print("new-feature:no-status-since-field-rule")

# every skill that itself flips Goal status must cite the third write
for rel in ("skills/create-github-issue/SKILL.md", "skills/execute-tasks/SKILL.md",
            "skills/doc-fix/SKILL.md", "skills/test/SKILL.md"):
    try:
        text = Path(rel).read_text()
    except FileNotFoundError:
        print(f"{rel}:missing")
        continue
    if not re.search(r"Status since", text):
        print(f"{rel}:flip-site-no-status-since")
PY
)
if [ -z "$gate26_errs" ]; then ok "Status-since timing protocol present (gate rule + template + every flip site)"; else bad "status-since protocol missing:$gate26_errs"; fi

# standardize-prose skill: frontmatter, references, ASD attribution, frozen modals.
STE_SKILL="skills/standardize-prose/SKILL.md"
ste_errs=""
if [ ! -f "$STE_SKILL" ]; then
  ste_errs=" $STE_SKILL:missing"
else
  $G -q '^name: standardize-prose' "$STE_SKILL" || ste_errs="$ste_errs ste:no-name"
  $G -q 'Aerospace, Security and Defence Industries' "$STE_SKILL" || ste_errs="$ste_errs ste:no-attribution"
  $G -q 'shall, must, will, may' "$STE_SKILL" || ste_errs="$ste_errs ste:no-frozen-modals"
fi
for ref in writing-rules.md software-terms.md; do
  REF="skills/standardize-prose/references/$ref"
  { [ -f "$REF" ] && $G -q 'Aerospace, Security and Defence Industries' "$REF"; } || ste_errs="$ste_errs ste:ref-$ref"
done
# rare/translated-term guarantee (issue #80): floor-not-ceiling, citation
# format, language qualifier, and the skill intro anchor are structural.
STE_TERMS="skills/standardize-prose/references/software-terms.md"
STE_RULES="skills/standardize-prose/references/writing-rules.md"
$G -q 'floor, not a ceiling' "$STE_TERMS" || ste_errs="$ste_errs ste:no-floor-not-ceiling"
$G -q '譯自' "$STE_TERMS" || ste_errs="$ste_errs ste:no-citation-format"
$G -qi 'non-English' "$STE_SKILL" || ste_errs="$ste_errs ste:no-non-english-anchor"
$G -q 'operative mechanism' "$STE_RULES" || ste_errs="$ste_errs ste:no-language-qualifier"
[ -z "$ste_errs" ] && ok "standardize-prose skill present with attribution + frozen-modals anchors" || bad "standardize-prose broken:$ste_errs"

# prose-quality rule blocks in brainstorm and plan (upstream track)
pq_errs=""
for sk in skills/brainstorm/SKILL.md skills/plan/SKILL.md; do
  $G -qi 'one term per concept' "$sk" || pq_errs="$pq_errs ${sk}:no-prose-block"
  $G -qi 'never swap' "$sk" || pq_errs="$pq_errs ${sk}:no-frozen-modals-rule"
done
[ -z "$pq_errs" ] && ok "brainstorm + plan carry prose-quality rule blocks" || bad "prose blocks missing:$pq_errs"

# Shared output rules: every skill loads the plugin-root reference and passes
# its contents into isolated subagent briefs.
output_errs=$(python3 -B - <<'PY'
from pathlib import Path
import re
skills = ("bootstrap", "brainstorm", "commit", "create-github-issue", "doc-fix",
          "document-structure", "execute-tasks", "new-feature", "new-idea", "open-pr",
          "plan", "review", "standardize-prose", "tdd", "test", "whats-new")
reference = Path("references/output-style.md")
if not reference.is_file():
    print("output-style:missing-reference")
for skill in skills:
    path = Path("skills") / skill / "SKILL.md"
    if not path.is_file():
        print(f"{skill}:missing")
        continue
    text = path.read_text()
    if "references/output-style.md" not in text or "load" not in text.lower():
        print(f"{skill}:no-shared-rule-load")
    section = re.search(r"## Output style\s+(.*?)(?=\n## |\Z)", text, re.S | re.I)
    if section is None or not re.search(r"pass.{0,100}actual contents.{0,100}subagent", section.group(1), re.I | re.S):
        print(f"{skill}:subagent-no-shared-rules")
routing = Path("references/model-routing.md").read_text()
if not re.search(r"native or CLI dispatch brief.{0,160}actual contents", routing, re.I | re.S):
    print("routing:no-native-cli-output-rules")
if not re.search(r"isolated reviewers.{0,100}directly", routing, re.I | re.S):
    print("routing:isolated-reviewer-no-output-rules")
PY
)
[ -z "$output_errs" ] && ok "shared output rules loaded and propagated" || bad "shared output rules missing:$output_errs"

# plan review pass + step-4 read-gate + bootstrap roles + red-team key
# retirement (issue #90). Concept greps scoped per file — never exact
# sentences (#38); key-shape probes, not bare words (#70).
pr_errs=""
PLAN_SKILL="skills/plan/SKILL.md"
$G -q '## Plan review pass' "$PLAN_SKILL" || pr_errs="$pr_errs plan:no-review-pass-section"
$G -q 'roles.reviewer' "$PLAN_SKILL" || pr_errs="$pr_errs plan:no-reviewer-key"
$G -q 'needs-rework' "$PLAN_SKILL" || pr_errs="$pr_errs plan:no-binary-verdict"
NF_SKILL="skills/new-feature/SKILL.md"
$G -q 'Plan review pass' "$NF_SKILL" || pr_errs="$pr_errs new-feature:no-pass-note"
CGI_SKILL="skills/create-github-issue/SKILL.md"
$G -q 'Plan review pass' "$CGI_SKILL" || pr_errs="$pr_errs cgi:no-standalone-gate"
BOOT="skills/bootstrap/SKILL.md"
$G -q '"reviewer": "session"' "$BOOT" || pr_errs="$pr_errs bootstrap:no-roles-template"
# retired key form: quoted JSON key or roles. dotted reference, in skills +
# routing doc + eval fixture (bare-word "red-team" role descriptions survive)
$G -q '"red-team"' skills/brainstorm/SKILL.md && pr_errs="$pr_errs retire:brainstorm-key"
$G -q '"red-team"' references/model-routing.md && pr_errs="$pr_errs retire:routing-key"
$G -q '"red-team"' evals/new-feature/cases/05-combined-ask-prefill/prompt.md && pr_errs="$pr_errs retire:fixture-key"
$G -q 'roles.red-team' skills/new-feature/SKILL.md && pr_errs="$pr_errs retire:newfeature-key"
[ -z "$pr_errs" ] && ok "plan review pass + read-gates + roles template + key retirement" || bad "plan-review wiring broken:$pr_errs"

# Codex reviewer model contract (#91). Scope checks to the host-specific
# section so a stray keyword elsewhere cannot stand in for a dispatch rule.
codex_errs=$(python3 -B - <<'PY'
import re
import sys
from pathlib import Path
sys.path.insert(0, "tests/lib")
from sections import section

routing = Path("references/model-routing.md").read_text()
codex = section(routing, "Codex reviewer model")
checks = {
    "config-key": r"codex_reviewer_model",
    "native-model-param": r"native.*`model`",
    "absent-default": r"absent.*omit.*`model`",
    "nonempty-string": r"nonempty string",
    "blank-rejected": r"whitespace-only",
    "wrong-types-rejected": r"null.*boolean.*number.*array.*object",
    "malformed-json": r"malformed JSON",
    "before-every-dispatch": r"[Bb]efore every.*dispatch",
    "blocked": r"BLOCKED.*(?:no|zero).*dispatch",
    "codex-ignores-roles": r"Codex.*ignore.*`roles`",
    "claude-ignores-key": r"Claude Code.*ignore.*`codex_reviewer_model`",
}
for name, pattern in checks.items():
    if not re.search(pattern, codex, re.S):
        print(f"routing:codex-{name}-missing")
if "Native model validation" not in codex:
    print("routing:codex-shared-native-validation-pointer-missing")
validation = section(routing, "Native model validation")
for name, pattern in {
    "authoritative-restriction": r"authoritative.{0,160}(?:restriction|allowlist|enum)|(?:restriction|allowlist|enum).{0,160}authoritative",
    "example-list-distinction": r"example.{0,160}(?:list|options)|(?:list|options).{0,160}example",
    "unlisted-attempt": r"absence.{0,120}list.{0,120}alone|unlisted|not listed",
    "string-model-dispatch": r"native tool.{0,180}accepts a string.*model|accepts a string `model`",
    "no-hardcoded-list": r"Do not hardcode a model availability list",
    "dispatch-rejection": r"dispatch itself rejects",
    "original-reason": r"preserve the original rejection reason",
    "rejection-no-fallback": r"Never fall back",
    "rejection-correction-resume": r"rejection.{0,180}(?:correct|enable|configur).{0,180}(?:exact|requested).{0,180}(?:resume|retry)|(?:correct|enable|configur).{0,180}(?:exact|requested).{0,180}(?:resume|retry)",
    "provider-enable-hint": r"provider.{0,160}(?:enable|configur).{0,160}(?:exact|requested).{0,100}(?:model|provider)",
}.items():
    if not re.search(pattern, validation, re.I | re.S):
        print(f"routing:codex-{name}-missing")
schema = section(routing, "Config schema")
if '"codex_reviewer_model"' not in schema:
    print("routing:codex-config-example-missing")

paths = (
    ("brainstorm", "Model routing"),
    ("plan", "Plan review pass"),
    ("review", "Dispatch the reviewer subagent"),
    ("review", "Focused review"),
)
for skill, heading in paths:
    body = section(Path(f"skills/{skill}/SKILL.md").read_text(), heading)
    for marker in ("Codex", "codex_reviewer_model", "references/model-routing.md", "Codex reviewer model"):
        if marker not in body:
            print(f"{skill}:{heading}:missing-{marker}")
review = Path("skills/review/SKILL.md").read_text()
for heading in ("Before starting", "Standalone mode"):
    body = section(review, heading)
    if "Codex" not in body or "Claude Code" not in body:
        print(f"review:{heading}:host-precedence-missing")
plan_pass = section(Path("skills/plan/SKILL.md").read_text(), "Plan review pass")
if not re.search(r"[Ss]tandalone.*Codex", plan_pass, re.S):
    print("plan:standalone-codex-resolution-missing")
nf = Path("skills/new-feature/SKILL.md").read_text()
if "codex_reviewer_model" not in section(nf, "Step 7"):
    print("new-feature:step7-codex-routing-missing")

readme = Path("README.md").read_text()
if "codex_reviewer_model" not in readme or "references/model-routing.md" not in readme:
    print("readme:codex-config-undocumented")
bootstrap_text = Path("skills/bootstrap/SKILL.md").read_text()
branch_config = re.search(r"^### 3\. Branch config\n(.*?)(?=^### |\Z)", bootstrap_text, re.M | re.S)
bootstrap = branch_config[1] if branch_config else ""
for marker in ("codex_reviewer_model", "optional", "preserve", "absent"):
    if marker not in bootstrap:
        print(f"bootstrap:codex-config-{marker}-missing")
default_config = re.search(r"```json\s*(.*?)```", bootstrap, re.S)
if default_config and "codex_reviewer_model" in default_config[1]:
    print("bootstrap:codex-model-pinned-by-default")
PY
)
[ -z "$codex_errs" ] && ok "Codex reviewer config validates before native dispatch" || bad "Codex reviewer contract missing:$codex_errs"

# Issue creation must enforce the plan-pass read-gate in-flow before it advances
# status, and a failed step-4 gate must rewind the whole status mirror to step 3.
plan_gate_errs=$(python3 -B - <<'PY'
import sys
from pathlib import Path

issue = Path("skills/create-github-issue/SKILL.md").read_text()
new_feature = Path("skills/new-feature/SKILL.md").read_text()

gate = issue.split("## Gate check", 1)[1].split("## Why a fixed structure", 1)[0]
if "running inside dev-flow" not in gate or "read-gate" not in gate or "Plan review pass" not in gate:
    print("create-issue:no-in-flow-plan-pass-gate")
pass_check = gate.find("Before advancing status or drafting, check the referenced plan")
transition = gate.find("this skill owns step 4's transition to `issue`")
if pass_check < 0:
    print("create-issue:missing-before-transition-pass-check")
if transition < 0:
    print("create-issue:missing-transition-ownership")
elif pass_check < 0 or pass_check > transition:
    print("create-issue:status-advances-before-plan-pass")
if "standalone" not in gate or "no plan has no plan-pass requirement" not in gate:
    print("create-issue:plain-standalone-bug-path-lost")
if "predat" not in gate and "legacy" not in gate:
    print("create-issue:no-legacy-plan-exception")
if "rewind to `spec`" not in gate or "Status since:" not in gate:
    print("create-issue:failed-gate-does-not-rewind-in-flow")

state_file = issue.split("## State file (dev-flow only)", 1)[1].split("## What not to do", 1)[0]
if "Set **Goal status** to" in state_file or "with the Status since timestamp" in state_file:
    print("create-issue:state-section-repeats-status-transition")
if "index row's Issue, Branch, and Updated fields" not in state_file:
    print("create-issue:published-issue-index-sync-missing")

step4 = new_feature.split("## Step 4", 1)[1].split("## Step 5", 1)[0]
for term in ("planning", "spec", "Status since", "index", "pass", "sub-skill owns this rewind", "do not repeat it here"):
    if term not in step4:
        print("new-feature:step4-missing-recovery-" + term.replace(" ", "-"))
if "before" not in step4.lower() or "issue" not in step4:
    print("new-feature:step4-transition-order-unclear")
PY
)
if [ -z "$plan_gate_errs" ]; then ok "step-4 plan-pass gate and resume rewind are structurally present"; else bad "step-4 plan gate broken:$plan_gate_errs"; fi
