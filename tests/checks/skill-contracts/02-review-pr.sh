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

# Per-step main/focused reviewer groups (issue #100, task 3). The shared
# routing contract owns selection and batch mechanics; these consumer checks
# ensure review applies them without weakening R5 or the risk/lifecycle gates.
review_group_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

review = Path("skills/review/SKILL.md").read_text()
new_feature = Path("skills/new-feature/SKILL.md").read_text()

main = re.search(r"^## Dispatch the reviewer subagent\s+(.*?)(?=^## The review )", review, re.M | re.S)
main = main.group(1) if main else ""
focused = re.search(r"^## Focused review\b(.*?)(?=^## Standalone mode\b)", review, re.M | re.S)
focused = focused.group(1) if focused else ""
for group, body in (("main", main), ("focused", focused)):
    if not re.search(r"(?:main_review|focused_review).{0,180}(?:group|reviewer list|route)|(?:group|reviewer list|route).{0,180}(?:main_review|focused_review)", body, re.I | re.S):
        print(f"review:{group}-step-route-not-resolved")
    if not re.search(r"every member.{0,180}(?:complete|valid|report)|(?:complete|valid|report).{0,180}every member", body, re.I | re.S):
        print(f"review:{group}-does-not-require-every-member")
    if not re.search(r"unique.{0,120}(?:report|destination|path)|(?:report|destination|path).{0,120}unique", body, re.I | re.S):
        print(f"review:{group}-no-isolated-report-paths")
    if not re.search(r"red.{0,120}(?:blocks|blocker|hard gate)|(?:blocks|blocker|hard gate).{0,120}red", body, re.I | re.S):
        print(f"review:{group}-red-blocker-missing")
if not re.search(r"absent.{0,180}(?:fallback|existing).{0,180}(?:route|selection|ask)|(?:fallback|existing).{0,180}(?:route|selection|ask).{0,180}absent", review, re.I | re.S):
    print("review:no-fallback-only-when-step-is-absent")
if not re.search(r"focused.{0,220}after.{0,100}(?:main|R5).{0,180}(?:clear|green|blue)", review, re.I | re.S):
    print("review:focused-does-not-follow-main-clearance")
if not re.search(r"green clears directly; blue and yellow.{0,180}(?:recorded note-in-PR|user chooses note-in-PR)", review, re.I | re.S):
    print("review:blue-focused-dispatch-bypasses-r5-choice")
if not re.search(r"green directly; blue and yellow only after the user chooses note-in-PR", new_feature, re.I):
    print("new-feature:blue-focused-dispatch-bypasses-r5-choice")
if not re.search(r"Focused verdict.{0,180}(?:aggregate|group).{0,120}(?:pending|current|round)|(?:aggregate|group).{0,120}Focused verdict", review, re.I | re.S):
    print("review:focused-aggregate-not-written-to-existing-field")
if not re.search(r"(?:fix|changed).{0,180}(?:rerun|re-review).{0,180}(?:all|every).{0,100}reviewer", review, re.I | re.S):
    print("review:fix-does-not-invalidate-entire-group")
if not re.search(r"read-only reviewer.{0,180}(?:returns|return).{0,100}report.{0,180}(?:verbatim|without judging|without editorial)", review, re.I | re.S):
    print("review:cli-report-transport-not-verbatim")
if not re.search(r"main_review|focused_review", new_feature):
    print("new-feature:no-per-step-reviewer-guidance")
if not re.search(r"focused reviewer.{0,180}(?:high|risk).{0,180}(?:waiv|not waived)|(?:high|risk).{0,180}(?:waiv|not waived).{0,180}focused reviewer", new_feature, re.I | re.S):
    print("new-feature:step7-risk-conditional-review-missing")
if not re.search(r"Risk tier.{0,240}Focused verdict.{0,240}(?:pending|not required)", new_feature, re.I | re.S):
    print("new-feature:focused-verdict-lifecycle-missing")
PY
)
[ -z "$review_group_errs" ] && ok "main and focused reviewer groups preserve R5, risk, and re-review gates" || bad "reviewer-group consumer contract missing:$review_group_errs"

# First-publication recovery is authorized only after current Step 8 evidence
# is rechecked; stale evidence rewinds and unreadable evidence remains pending.
first_publication_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

text = Path("skills/new-feature/SKILL.md").read_text()
resume = re.search(r"^## Resume\s+(.*?)(?=^## Preflight)", text, re.M | re.S)
body = resume.group(1) if resume else ""
if not re.search(r"successful lookup with zero matches.{0,300}Before authorizing Step 9.{0,120}current Step 8 evidence", body, re.I | re.S):
    print("resume:first-publication-does-not-require-current-step-8-evidence")
if not re.search(r"stale.{0,140}(?:HEAD|head|base|verification).{0,180}(?:execute|verification rewind)", body, re.I | re.S):
    print("resume:first-publication-stale-evidence-does-not-rewind")
if not re.search(r"unreadable.{0,140}(?:pending|stay pending)|(?:pending|stay pending).{0,140}unreadable", body, re.I | re.S):
    print("resume:first-publication-unreadable-evidence-not-pending")
if not re.search(r"tuple.{0,180}match.{0,120}missing only.{0,100}documentation judgment.{0,180}supplement", body, re.I | re.S):
    print("resume:first-publication-missing-doc-judgment-route-absent")
step8 = re.search(r"^## Step 8\b(.*?)(?=^## Step 9\b)", text, re.M | re.S)
step8_body = step8.group(1) if step8 else ""
if not re.search(r"pr-review.{0,100}doc-fix.{0,180}(?:three|all three) mirrored writes", step8_body, re.I | re.S):
    print("step8:first-publication-supplement-transition-not-mirrored")
if not re.search(r"Step 9's normal.{0,100}doc-fix.{0,100}pr-review.{0,20}transition", step8_body, re.I | re.S):
    print("step8:first-publication-supplement-return-bypasses-normal-gate")
PY
)
[ -z "$first_publication_errs" ] && ok "first-publication re-entry requires current Step 8 evidence" || bad "first-publication recovery contract missing:$first_publication_errs"

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
if not re.search(r"verified `pr-review` entry context.{0,180}Step 8 documentation-consistency evidence.{0,180}do not publish", open_pr, re.I | re.S):
    print("open-pr:publication-can-bypass-documentation-evidence")
if not re.search(r"In-flow edits remain part of the task's changes and verification.{0,180}test and review run afterward", doc_fix, re.I | re.S):
    print("doc-fix:in-flow-edits-do-not-enter-test-and-review")
if not re.search(r"execute.{0,100}re-entry", execute, re.I):
    print("execute:repair-reentry-not-supported")
if not re.search(r"unpushed local head remains recorded but cannot pass the remote PR", new_feature, re.I | re.S):
    print("step10:unpushed-local-fix-not-kept-pending")
if not re.search(r"Invoke it, then run Step 10 automatically", step9_body):
    print("step9:does-not-enter-step10-automatically")
if not re.search(r"same PR version and same reason.{0,180}without a new change.{0,180}stop retrying", new_feature, re.I | re.S):
    print("step10:no-progress-loop-does-not-stop")

# A crash before initial publication must not become an existing-PR repair.
if not re.search(r"confirmed no PR was ever created.{0,180}first-publication re-entry at `pr-review`", resume_body, re.I | re.S):
    print("resume:no-first-publication-reentry")
if not re.search(r"all states.{0,180}source branch.{0,100}target", resume_body, re.I | re.S):
    print("resume:no-all-state-duplicate-check")
if not re.search(r"(?:failed|unreadable|ambiguous).{0,180}pending", resume_body, re.I | re.S):
    print("resume:failed-lookup-can-authorize-creation")

references = new_feature.split("## References\n", 1)[1].split(chr(96) * 3, 1)[0]
for field in ("Repository", "PR URL"):
    if not re.search(rf"^- {field}:", references, re.M):
        print(f"state:missing-{field.lower().replace(' ', '-')}")
record = open_pr.split("## Record and hand back", 1)[1].split("## Standalone mode", 1)[0]
if not all(field in record for field in ("Repository", "PR URL", "owner/repo")):
    print("open-pr:does-not-persist-complete-pr-identity")
step10 = new_feature.split("## Step 10 —", 1)[1].split("## Step 11 —", 1)[0]
if not re.search(r"legacy.{0,240}remote.{0,240}verify.{0,240}References", step10, re.I | re.S):
    print("step10:no-verified-legacy-identity-recovery")
PY
)
if [ -z "$repair_loop_errs" ]; then ok "Post-PR repair loops retain PR identity and version evidence"; else bad "Post-PR repair-loop contract missing:$repair_loop_errs"; fi

# Reviews and PR publication use the approved criteria and evidence; they do
# not invent criteria or turn missing UI evidence into a success claim.
acceptance_evidence_errs=$(python3 -B - <<'PY'
from pathlib import Path

review = Path("skills/review/SKILL.md").read_text()
test = Path("skills/test/SKILL.md").read_text()
open_pr = Path("skills/open-pr/SKILL.md").read_text()
if "do not write a competing requirement set" not in review:
    print("review:creates-independent-requirements")
if "mark that criterion unverified" not in test:
    print("test:missing-unverified-environment-outcome")
if "ask the user to confirm any scope change" not in open_pr or "relax an existing one" not in open_pr:
    print("open-pr:scope-change-can-be-silent")
PY
)
[ -z "$acceptance_evidence_errs" ] && ok "review and PR evidence remain bound to agreed criteria" || bad "acceptance evidence contract missing:$acceptance_evidence_errs"

# The retained doc-fix checkpoint verifies evidence; it does not dispatch the
# standalone skill or bypass review and confirmation after newly found drift.
doc_checkpoint_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

workflow = Path("skills/new-feature/SKILL.md").read_text()
doc_fix = Path("skills/doc-fix/SKILL.md").read_text()
review = Path("skills/review/SKILL.md").read_text()
step8 = re.search(r"^## Step 8\b(.*?)(?=^## Step 9\b)", workflow, re.M | re.S)
body = step8.group(1) if step8 else ""
if re.search(r"Invoke `dev-flow:doc-fix`", body):
    print("step8:fixed-doc-fix-dispatch-remains")
if not re.search(r"documentation[- ]consistency.{0,160}(?:evidence|result)|(?:evidence|result).{0,160}documentation[- ]consistency", body, re.I | re.S):
    print("step8:does-not-check-documentation-evidence")
if not re.search(r"new drift.{0,180}(?:execute|confirmation)|(?:execute|confirmation).{0,180}new drift", body, re.I | re.S):
    print("step8:new-drift-does-not-return-through-build")
supplement = re.search(r"Missing documentation judgment only:(.*?)(?=\n\*\*New drift|\Z)", body, re.S)
supplement_text = supplement.group(1) if supplement else ""
if not re.search(r"Test and Review identity tuple matches.{0,160}relevant worktree is clean", supplement_text, re.I | re.S):
    print("step8:supplement-not-limited-to-matching-clean-evidence")
if re.search(r"stale.{0,140}use `dev-flow:review`'s explicit Step 8", body, re.I | re.S):
    print("step8:stale-evidence-routed-to-docs-only-supplement")
if not re.search(r"Relevant uncommitted changes block the checkpoint and any supplement", body, re.I):
    print("step8:relevant-dirty-tree-not-left-pending")
if not re.search(r"explicit in-flow context.{0,180}Goal status.*`execute`", doc_fix, re.I | re.S):
    print("doc-fix:in-flow-entry-context-missing")
if not re.search(r"When invoked without a state file", doc_fix):
    print("doc-fix:standalone-use-removed")
if not re.search(r"final documentation consistency", review, re.I):
    print("review:final-documentation-review-missing")
PY
)
[ -z "$doc_checkpoint_errs" ] && ok "doc-fix checkpoint validates build and review evidence without redispatch" || bad "doc-fix checkpoint contract missing:$doc_checkpoint_errs"

# R4 must load both checklists in-process and in isolated reviewer briefs.
architecture_errs=$(python3 -B - <<'PYARCH'
from pathlib import Path

review = Path("skills/review/SKILL.md").read_text()
reference = Path("skills/review/references/architecture.md")
if not reference.is_file():
    print("architecture:missing-reference")
for label, section in (
    ("dispatch", review.split("4. **The methodology**", 1)[-1].split("5. **Report contract**", 1)[0]),
    ("R4", review.split("### R4.", 1)[-1].split("### R5.", 1)[0]),
):
    for name in ("clean-code.md", "architecture.md"):
        if name not in section:
            print(f"{label}:missing-{name}")
    if "both" not in section or "read" not in section.lower():
        print(f"{label}:missing-both-read-requirement")
PYARCH
)
if [ -z "$architecture_errs" ]; then ok "R4 and isolated reviewers load both architecture and clean-code references"; else bad "architecture checklist wiring missing:$architecture_errs"; fi
