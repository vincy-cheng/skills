# tests/checks/skill-contracts/02-review-pr.sh — pre/ship PR review contract checks.
# Sourced by tests/checks/03-skill-contracts.sh; cwd is repo root.

# post-PR review evidence contract: test and review reports are tied to the
# exact repository head and base they checked, and dirty/legacy evidence fails closed.
evidence_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

new_feature = Path("skills/new-feature/SKILL.md").read_text()
test_skill = Path("skills/test/SKILL.md").read_text()
review_skill = Path("skills/review/SKILL.md").read_text()

required_fields = ("Repository", "Head SHA", "Base ref", "Base SHA", "Report path", "Verdict", "Time")
state_section = new_feature.split("### Per-feature state file", 1)[-1].split("### Index file", 1)[0]
if "## Verification evidence" not in state_section:
    print("state:no-verification-evidence-section")
else:
    for field in ("Test evidence", "Review evidence"):
        if field not in state_section:
            print(f"state:missing-{field.lower().replace(' ', '-')}")
    if not all(field in state_section for field in required_fields):
        print("state:missing-version-evidence-fields")
    if not re.search(r"uncommitted path.{0,100}proven irrelevant", state_section, re.I | re.S):
        print("state:no-irrelevant-dirty-path-exception")
    if not re.search(r"uncommitted path may affect.{0,100}stop", state_section, re.I | re.S):
        print("state:no-relevant-dirty-path-stop")
    if not re.search(r"report completion.{0,100}recheck", state_section, re.I | re.S):
        print("state:no-completion-recheck")
    if not re.search(r"old state.{0,100}(missing|absent)|(?:missing|absent).{0,100}old state", state_section, re.I | re.S):
        print("state:no-legacy-evidence-rule")

for label, text in (("test", test_skill), ("review", review_skill)):
    if not all(field in text for field in ("Repository", "Head SHA", "Base ref", "Base SHA")):
        print(f"{label}:report-missing-head-base-evidence")
    if not re.search(r"uncommitted path may affect.{0,100}stop", text, re.I | re.S):
        print(f"{label}:no-relevant-dirty-path-stop")
    if not re.search(r"uncommitted path.{0,100}proven irrelevant", text, re.I | re.S):
        print(f"{label}:no-irrelevant-dirty-path-exception")
    if not re.search(r"report completion.{0,100}recheck", text, re.I | re.S):
        print(f"{label}:no-completion-recheck")
    if not re.search(r"evidence.{0,120}(report|path)|(report|path).{0,120}evidence", text, re.I | re.S):
        print(f"{label}:evidence-not-linked-to-report")
PY
)
if [ -z "$evidence_errs" ]; then ok "test and review reports carry version-bound evidence"; else bad "verification evidence contract missing:$evidence_errs"; fi

# post-PR review reuses matching evidence, incrementally reviews trusted descendants,
# and falls back to a full review whenever ancestry or base evidence is stale.
incremental_review_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

new_feature = Path("skills/new-feature/SKILL.md").read_text()
review = Path("skills/review/SKILL.md").read_text()

step10_section = re.search(r"^## Step 10\b(.*?)(?=^## Step 11\b)", new_feature, re.M | re.S)
if not step10_section or not re.search(r"delegate.{0,240}pr-review.{0,80}validation subflow", step10_section.group(1), re.I | re.S):
    print("new-feature:step-10-does-not-delegate-post-pr-review")
if not re.search(r"repository, head SHA, base ref, and base SHA.{0,120}exactly match.{0,300}reuse", review, re.I | re.S):
    print("review:no-same-version-review-reuse")
if not re.search(r"R5 outcome.{0,120}clear to proceed", review, re.I | re.S):
    print("review:reuse-does-not-require-cleared-r5-outcome")
if not re.search(r"focused review.{0,160}(?:same version|version values).{0,100}waiver", review, re.I | re.S):
    print("review:reuse-ignores-required-focused-review-or-waiver")
if not re.search(r"git merge-base --is-ancestor", review):
    print("review:no-ancestor-proof-for-incremental-review")
incremental_eligibility = re.search(r"For a changed head, incremental review is allowed only when(.*?)(?=\n\n)", review, re.S)
if not incremental_eligibility or not re.search(r"R5.{0,120}clear|clear.{0,120}R5", incremental_eligibility.group(1), re.I | re.S):
    print("review:incremental-baseline-does-not-require-cleared-r5")
if not incremental_eligibility or not re.search(r"focused review.{0,160}(?:clear|waiver).{0,100}(?:report|same version|version values)|focused report.{0,160}(?:clear|waiver)", incremental_eligibility.group(1), re.I | re.S):
    print("review:incremental-baseline-does-not-require-focused-evidence")
if not re.search(r"eligibility fails.{0,120}risk recheck.{0,120}full diff", review, re.I | re.S):
    print("review:full-review-fallback-does-not-recheck-full-diff-risk")
if not re.search(r"base ref.{0,120}base SHA.{0,160}(?:match|unchanged|same)", review, re.I | re.S):
    print("review:no-base-version-check-for-incremental-review")
if not re.search(r"(?:incremental|full).{0,160}(?:report|verdict).{0,160}(?:valid|missing|fallback|complete)", review, re.I | re.S):
    print("review:no-report-validity-or-full-review-fallback")
if not re.search(r"<reviewed-head>\.\.\.?<current-head>|<reviewed-head>\.\.<current-head>", review):
    print("review:no-incremental-diff-range")
if not re.search(r"escalation-only risk recheck.{0,240}newly triggered high-risk category.{0,200}focused reviewer", review, re.I | re.S):
    print("review:no-risk-escalation-on-incremental-review")
if not re.search(r"design.{0,100}(?:confirm|approval).{0,120}full review|full review.{0,120}design.{0,100}(?:confirm|approval)", review, re.I | re.S):
    print("review:design-change-can-be-approved-by-full-review")
PY
)
if [ -z "$incremental_review_errs" ]; then ok "post-PR review reuses matching evidence and fails closed to full review"; else bad "incremental review contract missing:$incremental_review_errs"; fi

# Step 10 checks the remote PR and its required checks before the manual merge gate.
step10_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

new_feature = Path("skills/new-feature/SKILL.md").read_text()
test_skill = Path("skills/test/SKILL.md").read_text()
step10 = re.search(r"^## Step 10\b(.*?)(?=^## Step 11\b)", new_feature, re.M | re.S)
body = step10.group(1) if step10 else ""

for pattern, label in (
    (r"`pr-review`", "step10:no-pr-review-status"),
    (r"gh pr view", "step10:no-remote-pr-view"),
    (r"gh pr checks", "step10:no-required-check-query"),
    (r"300 seconds|five minutes|5 minutes", "step10:no-ci-timeout"),
    (r"unknown.{0,80}(?:pending|pass)|(?:pending|pass).{0,80}unknown", "step10:unknown-checks-not-fail-closed"),
    (r"closed.{0,80}unmerged", "step10:no-closed-unmerged-outcome"),
    (r"merged.{0,100}(?:remote|PR).{0,100}confirm|(?:remote|PR).{0,100}confirm.{0,100}merged", "step10:no-remote-merge-confirmation"),
):
    if not re.search(pattern, body, re.I | re.S):
        print(label)

if not re.search(r"PR check", body):
    print("step10:no-pr-check-record")
if not all(result in body for result in ("passed", "pending", "needs-fix")):
    print("step10:missing-distinct-results")
if not re.search(r"immediately record `merged`.{0,180}without readiness checks or old evidence", body, re.I | re.S):
    print("step10:no-early-merged-routing")
if not re.search(r"CLOSED.{0,180}keep `pr-review`", body, re.I | re.S):
    print("step10:no-early-closed-unmerged-routing")
if not re.search(r"Before any delegated test or review.{0,180}equal the captured PR tuple.{0,160}do not dispatch", body, re.I | re.S):
    print("step10:no-matching-checkout-dispatch-gate")
if not re.search(r"unknown mergeability", body, re.I):
    print("step10:unknown-mergeability-not-pending")
if not re.search(r"\| 10 PR check / merge \| `pr-review` \| `pr-review` while open or unresolved; `merged` only after remote merge confirmation \|", new_feature):
    print("new-feature:step10-gate-table-sets-merged-too-early")
if not re.search(r"300 seconds|five minutes|5 minutes", test_skill, re.I):
    print("test:no-step10-time-bounded-validation")
if not re.search(r"pr-review.{0,240}(?:return|back).{0,100}Step 10|Step 10.{0,240}(?:return|back).{0,100}pr-review", test_skill, re.I | re.S):
    print("test:no-step10-validation-return")
PY
)
if [ -z "$step10_errs" ]; then ok "Step 10 checks remote PR status and required checks before manual merge"; else bad "Step 10 PR check contract missing:$step10_errs"; fi

# Post-PR repair loops reuse the same PR and preserve the run's saved context.
repair_loop_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

new_feature = Path("skills/new-feature/SKILL.md").read_text()
open_pr = Path("skills/open-pr/SKILL.md").read_text()
execute = Path("skills/execute-tasks/SKILL.md").read_text()
doc_fix = Path("skills/doc-fix/SKILL.md").read_text()
resume = re.search(r"^## Resume\b(.*?)(?=^## Preflight\b)", new_feature, re.M | re.S)
step9 = re.search(r"^## Step 9\b(.*?)(?=^## Step 10\b)", new_feature, re.M | re.S)
resume_body = resume.group(1) if resume else ""
step9_body = step9.group(1) if step9 else ""

if not re.search(r"`pr-review`.{0,180}(?:existing|recorded).{0,120}PR", resume_body, re.I | re.S):
    print("resume:pr-review-does-not-inspect-existing-pr")
if not re.search(r"identity is missing.{0,120}(?:locate|find).{0,120}verify the existing PR", resume_body, re.I | re.S):
    print("resume:missing-pr-identity-does-not-find-existing-pr")
if not re.search(r"rewind to `execute` by updating Goal status.{0,180}index row.{0,160}Updated.{0,100}Status since", new_feature, re.I | re.S) or not re.search(r"Preserve the saved Roles block and existing Tasks", new_feature):
    print("repair:rewind-does-not-preserve-run-context-and-mirrors")
if not re.search(r"existing recorded PR.{0,180}update that same PR.{0,180}do not create another issue or PR", step9_body, re.I | re.S):
    print("step9:existing-pr-may-be-duplicated")
if not re.search(r"orchestrator's verified `pr-review` entry context", open_pr, re.I) or not re.search(r"orchestrator alone writes `pr-review`", open_pr, re.I):
    print("open-pr:orchestrator-status-context-not-defined")
if not re.search(r"invoked directly with `doc-fix`.{0,180}return to `/new-feature`.{0,180}do not publish", open_pr, re.I | re.S):
    print("open-pr:direct-call-can-publish-before-status-transition")
if not re.search(r"doc-fix.{0,160}(?:commit|new head).{0,220}(?:evidence|test).{0,220}Step 10", doc_fix, re.I | re.S):
    print("doc-fix:commit-does-not-invalidate-evidence")
if not re.search(r"execute.{0,100}re-entry", execute, re.I):
    print("execute:repair-reentry-not-supported")
if not re.search(r"unpushed local head remains recorded but cannot pass the remote PR", new_feature, re.I | re.S):
    print("step10:unpushed-local-fix-not-kept-pending")
if not re.search(r"Invoke it, then run Step 10 automatically", step9_body):
    print("step9:does-not-enter-step10-automatically")
if not re.search(r"same PR version and same reason.{0,180}without a new change.{0,180}stop retrying", new_feature, re.I | re.S):
    print("step10:no-progress-loop-does-not-stop")
PY
)
if [ -z "$repair_loop_errs" ]; then ok "Post-PR repair loops retain PR identity and version evidence"; else bad "Post-PR repair-loop contract missing:$repair_loop_errs"; fi
