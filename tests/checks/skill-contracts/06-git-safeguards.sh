# tests/checks/skill-contracts/06-git-safeguards.sh — Git safeguards contract checks.
# Sourced by tests/checks/03-skill-contracts.sh; cwd is repo root.

# Git operation safeguards (issue #97): narrated behavior eval and structural
# skill contract on the same required safeguards; keep it as one file-scoped
# Python probe, not another split checker.
git_guard_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

errors = []
files = {}
for rel in (
    "skills/create-github-issue/SKILL.md",
    "skills/open-pr/SKILL.md",
    "skills/new-feature/SKILL.md",
):
    try:
        files[rel] = Path(rel).read_text()
    except FileNotFoundError:
        errors.append(f"{rel}:missing")
    except OSError as error:
        errors.append(f"{rel}:unreadable:{error}")

create = files.get("skills/create-github-issue/SKILL.md", "")
open_pr = files.get("skills/open-pr/SKILL.md", "")
new_feature = files.get("skills/new-feature/SKILL.md", "")

create_checks = {
    "local-no-track-creation": r"git (?:switch --no-track -c|checkout --no-track -b)",
    "branch-upstream-verify": r"(?:verify|check).{0,220}upstream|upstream.{0,220}(?:verify|check)",
    "missing-upstream-normal": r"(?:missing|no) upstream.{0,240}(?:normal|expected)|normal.{0,240}(?:missing|no) upstream",
    "missing-target-restrictions-before-offer": r"target branch doesn't exist.{0,500}(?:read|check).{0,500}(?:user and repository|runtime).{0,500}restrictions?",
    "missing-target-prohibited-handoff": r"prohibited.{0,480}(?:re-ask|bypass).{0,480}(?:preserv|handoff|hand off)|preserv.{0,480}(?:prohibited|handoff).{0,480}(?:re-ask|bypass)",
    "new-branch-upstream-absence-required": r"new(?:ly created)?.{0,260}--no-track.{0,260}(?:no|absent|missing).{0,260}upstream",
    "upstream-check-error-distinguished": r"no upstream configured.{0,240}expected|upstream check failed",
}
for name, pattern in create_checks.items():
    if not re.search(pattern, create, re.I | re.S):
        errors.append(f"create-github-issue:{name}")

open_checks = {
    "restrictions-before-publish": r"restrictions?.{0,320}(?:push|publish|authorization)|(?:push|publish|authorization).{0,320}restrictions?",
    "cross-tool-prohibition": r"scripts?.{0,280}(?:CLI|API)|(?:CLI|API).{0,280}scripts?",
    "branch-upstream-identity": r"(?:branch|upstream).{0,240}(?:upstream|actual)|upstream.{0,240}(?:identity|current)",
    "wrong-target-upstream": r"track(?:s|ing)?.{0,240}target|target.{0,240}upstream",
    "mis-push-impact": r"(?:mis-push|impact).{0,280}(?:dev|target)|(?:dev|target).{0,280}(?:mis-push|impact)",
    "no-silent-tracking-fix": r"(?:do not|don't|without).{0,320}(?:track(?:s|ing)?|upstream)",
    "pause-preserve-local": r"(?:stop|pause).{0,320}(?:preserve|local)|(?:preserve|local).{0,320}(?:stop|pause)",
    "explicit-safe-refspec": r"explicit.{0,240}(?:refspec|branch)|origin\s+HEAD:\s*<|HEAD:\s*(?:<current-branch>|<branch>)",
    "no-publish-under-prohibition": r"(?:prohibit|unavailable|cannot publish|do not push|not authorized).{0,320}(?:stop|handoff|pending)|(?:stop|handoff|pending).{0,320}(?:prohibit|unavailable|cannot publish|do not push|not authorized)",
    "no-repeat-auth-request": r"(?:do not|don't|without).{0,320}(?:ask again|re-ask|authorization)",
    "manual-handoff-title-body": r"PR title.{0,400}PR body|PR body.{0,400}PR title|Closes #97.{0,400}PR title|PR title.{0,400}Closes #97",
    "manual-handoff-verification-steps": r"verification.{0,400}manual steps|manual steps.{0,400}verification",
    "no-false-publication-claim": r"(?:do not|never).{0,320}(?:claim|publish|merged|done).{0,320}",
}
for name, pattern in open_checks.items():
    if not re.search(pattern, open_pr, re.I | re.S):
        errors.append(f"open-pr:{name}")

new_feature_checks = {
    "restrictions-cross-tool": r"scripts?.{0,320}(?:CLI|API)|(?:CLI|API).{0,320}scripts?",
    "resume-honors-restrictions": r"[Rr]esume.{0,360}(?:restrict|prohibit)|restrictions?.{0,360}[Rr]esume",
    "pr-readiness-honors-restrictions": r"(?:restrict|prohibit).{0,360}(?:PR|readiness|check)|(?:PR|readiness|check).{0,360}(?:restrict|prohibit)",
    "no-pending-publication-success": r"pending.{0,320}(?:no|not).{0,320}(?:publication|PR)|do not.{0,320}(?:claim|publish|merged|done)",
    "close-through-pr-merge": r"(?:PR|merge).{0,320}(?:closing|close).{0,320}issue|issue.{0,320}(?:closing|close).{0,320}(?:PR|merge)",
    "no-direct-close-substitution": r"(?:do not|don't|never).{0,320}(?:direct directly|direct close|directly close|close directly)",
    "nondefault-branch-caveat": r"(?:non-default|not the default).{0,320}(?:auto-close|close automatically|auto-?close)",
    "close-out-no-remote-modification": r"close-out.{0,320}(?:remote|delete)|remote.{0,320}close-out",
}
for name, pattern in new_feature_checks.items():
    if not re.search(pattern, new_feature, re.I | re.S):
        errors.append(f"new-feature:{name}")

eval_text = ""
try:
    eval_text = Path(
        "evals/new-feature/cases/06-git-operation-safeguards/prompt.md"
    ).read_text()
except OSError as error:
    errors.append(f"eval:unreadable:{error}")

eval_markers = {
    "no-track": "--no-track",
    "origin-dev-upstream": "refs/remotes/origin/dev",
    "scripts": "scripts",
    "CLI": "CLI",
    "API": "API",
    "closes-97": "Closes #97",
    "manual-steps": "manual steps",
    "issue-97": "Issue #97",
}
for label, marker in eval_markers.items():
    if marker.lower() not in eval_text.lower():
        errors.append(f"eval:missing-{label}")

print("\n".join(errors))
PY
)
if [ -z "$git_guard_errs" ]; then
  ok "Git operation safeguards are present in workflow skills and eval"
else
  bad "git operation safeguards missing:$git_guard_errs"
fi
