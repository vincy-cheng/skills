# tests/checks/skill-contracts/05-status-prose-and-review-gates.sh — status, prose, and review-gate contract checks.
# Sourced by tests/checks/03-skill-contracts.sh; cwd is repo root.

# Step 2/3 handoff and Step 8 evidence decisions must remain outcome- and
# identity-bound. These guards deliberately look for the branch contract, not
# one exact sentence, so prose can stay readable.
checkpoint_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

nf = Path("skills/new-feature/SKILL.md").read_text()
plan = Path("skills/plan/SKILL.md").read_text()
resume = re.search(r"^## Resume\b(.*?)(?=^## Step 1\b)", nf, re.M | re.S)
step2 = re.search(r"^## Step 2\b(.*?)(?=^## Step 3\b)", nf, re.M | re.S)
step3 = re.search(r"^## Step 3\b(.*?)(?=^## Step 4\b)", nf, re.M | re.S)
step8 = re.search(r"^## Step 8\b(.*?)(?=^## Step 9\b)", nf, re.M | re.S)
resume_text = resume.group(1) if resume else ""
step2_text = step2.group(1) if step2 else ""
step3_text = step3.group(1) if step3 else ""
step8_text = step8.group(1) if step8 else ""
step8_gate = re.search(r"^\*\*Gate:\*\*(.*)$", step8_text, re.M)
step8_gate_text = step8_gate.group(1) if step8_gate else ""
hard_gate = re.search(r"^## The hard gate\b(.*?)(?=^## Resume\b)", nf, re.M | re.S)
hard_gate_text = hard_gate.group(1) if hard_gate else ""
red_loop = re.search(r"^\*\*Red-loop rewind:\*\*(.*?)(?=^\*\*Sub-skill handoffs)", hard_gate_text, re.M | re.S)
red_loop_text = red_loop.group(1) if red_loop else ""

if not re.search(r"`doc-fix`[^\n]{0,80}Step 8 evidence decision", resume_text, re.I):
    print("resume:does-not-delegate-to-step8-decision")
if re.search(r"`doc-fix`[^\n]{0,220}(?:supplement|stale|rewind)", resume_text, re.I):
    print("resume:duplicates-step8-policy")
if not re.search(r"Missing documentation judgment only.{0,500}use `dev-flow:review`'s explicit Step 8 documentation-evidence supplement", step8_text, re.I | re.S):
    print("step8:missing-judgment-supplement-path-absent")
if not re.search(r"Only a complete `consistent` result or a justified `N/A` advances to Step 9", step8_gate_text, re.I):
    print("step8:clean-result-not-explicitly-advances")
if not re.search(r"A complete `drift` result takes the confirmed repair path", step8_gate_text, re.I):
    print("step8:drift-does-not-take-repair-branch")
if not re.search(r"Missing or stale identity.{0,220}rewinds to `execute`.{0,220}fresh test and review", step8_gate_text, re.I | re.S):
    print("step8:stale-identity-does-not-rewind-to-full-verification")
if not re.search(r"Relevant uncommitted changes block the checkpoint.{0,100}stay pending at `doc-fix`", step8_gate_text, re.I | re.S):
    print("step8:dirty-relevant-worktree-not-left-pending")
if not re.search(r"unreadable, incomplete, or unresolved result stays pending at `doc-fix` and blocks Step 9", step8_gate_text, re.I):
    print("step8:unresolved-evidence-not-blocked")
if not re.search(r"Step 8 pending resume exception.{0,240}Goal status to `doc-fix`.{0,240}same Step 8 evidence decision.{0,120}no prior verdict", hard_gate_text, re.I | re.S):
    print("hard-gate:pending-doc-fix-resume-rejected-by-universal-gate")
if not re.search(r"First entry is `review`.{0,120}set `doc-fix`.{0,100}Pending resume exception", step8_gate_text, re.I | re.S) or not re.search(r"Step 8 has written `doc-fix` and is pending or was interrupted before its evidence decision completed.{0,160}accept incoming `doc-fix`.{0,160}without changing Goal status.{0,160}No prior verdict or recorded failure is required", step8_gate_text, re.I | re.S):
    print("step8:normal-entry-and-same-status-resume-not-distinguished")
if "| 8 doc-fix | `review` | `doc-fix` |" not in nf:
    print("gate-table:normal-review-to-doc-fix-transition-changed")
if re.search(r"steps 6 \(red\), 7 \(red\), and 8 \(STOP\)", red_loop_text):
    print("red-loop:generic-step8-stop-still-rewinds-pending-checkpoints")
if not re.search(r"Step 8 rewinds only for its explicit stale/missing identity or changed-verification outcome, or for a user-confirmed documentation repair", red_loop_text, re.I):
    print("red-loop:explicit-step8-rewind-outcomes-not-scoped")
def valid_step8_gate(text):
    return all((
        re.search(r"Only a complete `consistent` result or a justified `N/A` advances to Step 9", text, re.I),
        re.search(r"A complete `drift` result takes the confirmed repair path", text, re.I),
        re.search(r"Missing or stale identity.{0,220}rewinds to `execute`.{0,220}fresh test and review", text, re.I | re.S),
        re.search(r"Relevant uncommitted changes block the checkpoint.{0,100}stay pending at `doc-fix`", text, re.I | re.S),
        re.search(r"unreadable, incomplete, or unresolved result stays pending at `doc-fix` and blocks Step 9", text, re.I),
    ))

mutated_gate = step8_gate_text.replace("A complete `drift` result takes the confirmed repair path", "A complete `drift` result advances directly to Step 9")
if valid_step8_gate(mutated_gate):
    print("step8:decision-guard-accepts-direct-drift-advance-mutation")
if not re.search(r"Step 2.{0,100}viability validation.{0,100}unchanged current spec", step3_text, re.I | re.S):
    print("step3:does-not-reuse-current-step2-viability")
if not re.search(r"spec changed or this is a resume at `spec`, rerun Step 2's viability validation while Goal status remains `spec`", step3_text, re.I):
    print("step3:changed-or-resumed-material-not-revalidated")
if not re.search(r"Pass the spec identity and bound viability evidence into the plan invocation", step3_text, re.I):
    print("step3:current-validation-not-bound-to-plan-invocation")
step1 = re.search(r"^## Step 1\b(.*?)(?=^## Step 2\b)", nf, re.M | re.S)
if not step1 or not re.search(r"approved spec", step1.group(1), re.I) or not re.search(r"complete current.{0,100}(?:Plan review pass|pass)", step3_text, re.I | re.S):
    print("define:approval-checkpoint-missing")
if not re.search(r"orchestrated Step 2.{0,180}explicitly supplies.{0,100}spec identity.{0,100}viability evidence", plan, re.I | re.S):
    print("plan:bound-define-viability-cannot-be-reused")
if not re.search(r"Otherwise validate it here", plan, re.I):
    print("plan:standalone-or-unbound-spec-skips-viability-validation")
PY
)
[ -z "$checkpoint_errs" ] && ok "define handoff and Step 8 outcome/identity gates present" || bad "checkpoint contract missing:$checkpoint_errs"

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

# Acceptance contract: merged is not done until required user confirmation and
# evidence are complete; legacy specs may be completed but not approval-guessed.
acceptance_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

new_feature = Path("skills/new-feature/SKILL.md").read_text()
brainstorm = Path("skills/brainstorm/SKILL.md").read_text()
plan = Path("skills/plan/SKILL.md").read_text()
test = Path("skills/test/SKILL.md").read_text()
review = Path("skills/review/SKILL.md").read_text()
open_pr = Path("skills/open-pr/SKILL.md").read_text()
step11 = re.search(r"^## Step 11\b(.*?)(?=^## Notes\b)", new_feature, re.M | re.S)
closeout = step11.group(1) if step11 else ""
if not re.search(r"required user confirmation.{0,180}(?:missing|not obtained).{0,160}keep `merged`", closeout, re.I | re.S):
    print("closeout:missing-confirmation-can-still-mark-done")
legacy_contract = brainstorm + plan
if not re.search(r"legacy.{0,220}acceptance", legacy_contract, re.I | re.S) or not re.search(r"ask the user.{0,120}do not guess", legacy_contract, re.I | re.S):
    print("legacy-spec:missing-acceptance-recovery-without-guessing")
if not re.search(r"implementation complete.{0,100}acceptance.{0,100}user confirmation", new_feature, re.I | re.S):
    print("statuses:completion-and-confirmation-not-distinguished")
for name, text in (("brainstorm", brainstorm), ("plan", plan), ("test", test), ("review", review), ("open-pr", open_pr)):
    if not re.search(r"acceptance.{0,140}(?:evidence|example|boundary|verification)|(?:evidence|example|boundary|verification).{0,140}acceptance", text, re.I | re.S):
        print(f"{name}:acceptance-contract-not-carried")
if not re.search(r"PR ready.{0,120}merged.{0,120}done", new_feature, re.I | re.S):
    print("statuses:pr-ready-merged-done-not-distinguished")
PY
)
[ -z "$acceptance_errs" ] && ok "acceptance evidence, legacy recovery, and close-out confirmation contract present" || bad "acceptance contract missing:$acceptance_errs"

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

# Work-size classification must choose the plan review depth without weakening
# final/test/review gates or accepting an evidence-free self-check (#108).
size_errs=$(python3 -B - <<'PY'
from pathlib import Path
import re
import sys
sys.path.insert(0, "tests/lib")
from sections import section

plan = Path("skills/plan/SKILL.md").read_text()
task_rules = section(plan, "Task rules")
review_pass = section(plan, "Plan review pass")
standalone = section(plan, "Standalone mode")

requirements = {
    "small-task-limit": r"≤\s*3 tasks|at most three tasks",
    "single-existing-behavior": r"single existing behavior|one existing behavior",
    "shared-context": r"shared context",
    "no-unresolved-dependency": r"no unresolved architecture.*cross-system|without unresolved architecture.*cross-system",
    "all-low": r"every `Risk:` line `low`|all.*`Risk: low`",
    "ordinary-fallback": r"[Oo]therwise.*ordinary|ordinary.*otherwise",
    "missing-data-fail-closed": r"[Mm]issing|insufficient",
}
for name, pattern in requirements.items():
    if not re.search(pattern, task_rules, re.S):
        print(f"plan:task-rules-{name}-missing")
if "self-check" not in review_pass.lower():
    print("plan:small-self-check-missing")
if not re.search(r"ordinary.*independent|independent.*ordinary", review_pass, re.S):
    print("plan:ordinary-independent-review-missing")
if not re.search(r"(?:missing|incomplete|blocked).{0,180}(?:required )?review.{0,180}draft|draft.{0,180}(?:missing|incomplete|blocked).{0,180}(?:required )?review", review_pass, re.I | re.S):
    print("plan:incomplete-review-does-not-leave-draft")
if not re.search(r"user approval.{0,180}(?:does not|cannot).{0,120}(?:clear|satisfy|complete)", review_pass, re.I | re.S):
    print("plan:user-approval-cannot-clear-incomplete-review")
if not re.search(r"complete applicable pass.{0,220}separate user approval", review_pass, re.I | re.S):
    print("plan:handoff-does-not-require-complete-pass-and-separate-approval")
if not re.search(r"standalone.{0,200}(?:stop|never).*implementation|never.{0,160}standalone.{0,160}implementation", standalone, re.I | re.S):
    print("plan:standalone-auto-continuation-missing-stop")
for marker in ("classification basis", "applicability", "self-check", "independent review", "verdict"):
    if marker not in review_pass.lower():
        print(f"plan:pass-recording-{marker.replace(' ', '-')}-missing")
if "standalone" not in standalone.lower() or "insufficient" not in standalone.lower():
    print("plan:standalone-insufficient-evidence-rule-missing")

issue = Path("skills/create-github-issue/SKILL.md").read_text()
gate = section(issue, "Gate check")
if "Plan review pass" not in gate:
    print("issue:pass-record-missing")
if not re.search(r"eligib", gate, re.I):
    print("issue:pass-eligibility-missing")
if not re.search(r"self-check", gate, re.I):
    print("issue:pass-self-check-missing")
if not re.search(r"independent", gate, re.I):
    print("issue:pass-independent-review-missing")

new_feature = Path("skills/new-feature/SKILL.md").read_text()
step3 = section(new_feature, "Step 3 — Plan")
for marker in ("size", "self-check", "independent"):
    if marker not in step3.lower():
        print(f"new-feature:step3-{marker}-missing")
for recheck in ("before approval", "task.*scope", "repair"):
    if not re.search(recheck, step3, re.S | re.I):
        print("new-feature:step3-recheck-missing")
if "self-check" not in section(new_feature, "Step 4 — Create issue").lower():
    print("new-feature:step4-self-check-missing")
brainstorm_text = Path("skills/brainstorm/SKILL.md").read_text()
viability = brainstorm_text.split("\n## Model routing\n", 1)[0]
review_pass = section(plan, "Plan review pass")

# Task 2 (#100): reviewer-group consumers point to the shared batch contract,
# and gates require completed evidence rather than headings or claimed dispatch.
route_pointer = "references/model-routing.md"
for rel, key in (("skills/brainstorm/SKILL.md", "red_team"),
                 ("skills/plan/SKILL.md", "plan_review"),
                 ("skills/create-github-issue/SKILL.md", "plan_review"),
                 ("skills/new-feature/SKILL.md", "red_team")):
    text = Path(rel).read_text()
    if key not in text:
        print(f"{rel}:{key}-route-missing")
    if route_pointer not in text:
        print(f"{rel}:batch-contract-pointer-missing")

if not re.search(r"completed.*report|report.*completed", viability, re.I | re.S):
    print("brainstorm:viability-completion-evidence-missing")
if not re.search(r"coverage.*adversarial|adversarial.*coverage", review_pass, re.I | re.S):
    print("plan:adversarial-dimension-missing")
if not re.search(r"every reviewer.*both|both.*every reviewer", review_pass, re.I | re.S):
    print("plan:per-reviewer-both-dimensions-missing")
if not re.search(r"material identity|reviewed revision", review_pass, re.I):
    print("plan:material-identity-missing")
step2 = section(new_feature, "Step 2 — Spec")
if not re.search(r"legacy.*explicit.*record|explicit.*legacy.*record", step2, re.I | re.S):
    print("new-feature:legacy-viability-choice-not-recorded")
step3 = section(new_feature, "Step 3 — Plan")
if not re.search(r"incoming `spec`.{0,300}spec changed or this is a resume at `spec`.{0,180}rerun Step 2's viability validation while Goal status remains `spec`.{0,500}set `planning`", step3, re.I | re.S):
    print("new-feature:step3-does-not-preserve-gate-and-revalidation-order")
if not re.search(r"legacy.*explicit.*record|explicit.*legacy.*record", plan, re.I | re.S):
    print("plan:legacy-viability-choice-not-recorded")

brainstorm = Path("skills/brainstorm/SKILL.md").read_text()
viability = brainstorm.split("\n## Model routing\n", 1)[0]
for marker in ("requirement boundary", "decomposition feasibility"):
    if marker not in viability.lower():
        print(f"brainstorm:viability-{marker.replace(' ', '-')}-missing")

review = Path("skills/review/SKILL.md").read_text()
focused = section(review, "Focused review")
if "deep-scan" not in focused.lower() or not re.search(r"not.*redo|without.*redo", focused, re.I | re.S):
    print("review:focused-scope-contract-missing")
PY
)
if [ -z "$size_errs" ]; then ok "plan size classification and conditional review pass are evidenced"; else bad "plan-size review contract broken:$size_errs"; fi

# Step 6/7 orchestrators persist their destination status before invoking the
# engines; ordinary engine entry gates must read that live status. Step 8/10
# delegated modes remain explicit exceptions.
verify_gate_errs=$(python3 -B - <<'PY'
from pathlib import Path
import re

def section(text, heading, next_heading=None):
    end = rf"(?=^## {re.escape(next_heading)}(?=\s|$))" if next_heading else r"\Z"
    match = re.search(rf"^## {re.escape(heading)}(?=\s|$)(.*?){end}", text, re.M | re.S)
    return match.group(1) if match else ""

orchestrator = Path("skills/new-feature/SKILL.md").read_text()
step6 = section(orchestrator, "Step 6 — Test", "Step 7 — Review")
step7 = section(orchestrator, "Step 7 — Review", "Step 8 — Documentation consistency checkpoint")
if not re.search(r"Gate:.*`execute`\s*→\s*set `test` before invoking `dev-flow:test`", step6):
    print("new-feature:step6-incoming-or-destination-status-changed")
if not re.search(r"set `test`.{0,300}before invoking `dev-flow:test`", step6, re.I | re.S):
    print("new-feature:step6-does-not-persist-test-before-engine")
if not re.search(r"Gate:.*`test`\s*→\s*set `review` before invoking `dev-flow:review`", step7):
    print("new-feature:step7-incoming-or-destination-status-changed")
if not re.search(r"set `review`.{0,900}before invoking `dev-flow:review`", step7, re.I | re.S):
    print("new-feature:step7-does-not-persist-review-before-engine")

test_skill = Path("skills/test/SKILL.md").read_text()
test_gate = section(test_skill, "Gate (dev-flow, between step 5 and 7)", "Before starting")
if not re.search(r"ordinary Step 6 delegation.{0,150}requires live \*\*Goal status\*\* `test`", test_gate, re.I | re.S):
    print("test:ordinary-entry-does-not-require-live-test-status")
if not re.search(r"Step 6.{0,100}sets it before (?:invoking|calling) this skill", test_gate, re.I | re.S):
    print("test:orchestrator-delegation-not-explicit")
if "Step 10" not in test_gate or "`pr-review`" not in test_gate:
    print("test:step10-exception-lost")

review_skill = Path("skills/review/SKILL.md").read_text()
review_gate = section(review_skill, "Gate (dev-flow, step 7)", "Post-PR validation")
if not re.search(r"ordinary Step 7 delegation.{0,150}requires live \*\*Goal status\*\* `review`", review_gate, re.I | re.S):
    print("review:ordinary-entry-does-not-require-live-review-status")
if not re.search(r"Step 7 sets it before invoking this skill", review_gate):
    print("review:orchestrator-delegation-not-explicit")
if "Step 10" not in review_gate or "`pr-review`" not in review_gate or "Step 8" not in review_gate or "`doc-fix`" not in review_gate:
    print("review:step8-or-step10-exception-lost")
step10 = section(orchestrator, "Step 10 — PR check and manual merge", "Step 11 — Close-out")
if not re.search(r"ordinary step-7 `review` status gate", step10):
    print("review:step10-cross-reference-stale")
PY
)
[ -z "$verify_gate_errs" ] && ok "step 6/7 engine gates match persisted orchestrator statuses" || bad "step 6/7 handoff contract broken:$verify_gate_errs"
