# tests/checks/03-skill-contracts.sh — per-skill text guards.
# sourced by tests/check.sh; cwd is repo root.
# The two python heredoc checks import section() from tests/lib/sections.py
# (python3 -B, sys.path preamble — see the spec's shared-python section).

# plan skill exists with correct frontmatter and its contract-first mandates
PLAN_SKILL="skills/plan/SKILL.md"
plan_errs=""
if [ ! -f "$PLAN_SKILL" ]; then
  plan_errs=" $PLAN_SKILL:missing"
else
  $G -q '^name: plan' "$PLAN_SKILL" || plan_errs="$plan_errs plan:no-name"
  $G -q '## Flow Chart' "$PLAN_SKILL" || plan_errs="$plan_errs plan:no-flow-chart-mandate"
  $G -q 'docs/features/plans/' "$PLAN_SKILL" || plan_errs="$plan_errs plan:no-save-path"
fi
[ -z "$plan_errs" ] && ok "plan skill present with contract-first mandates" || bad "plan skill broken:$plan_errs"

# Codex has a new-feature skill that carries the full gated workflow.
skill_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

path = Path("skills/new-feature/SKILL.md")
try:
    text = path.read_text()
except FileNotFoundError:
    print("skill-missing")
except OSError as error:
    print(f"skill-unreadable:{error}")
else:
    header = text.split("---", 2)
    metadata = header[1] if len(header) == 3 and header[0] == "" else ""
    if not re.search(r"^name: new-feature$", metadata, re.M):
        print("name-missing")
    if not re.search(r"^description:\s*\S", metadata, re.M):
        print("description-missing")
    if re.findall(r"^## Step (\d+)\b", text, re.M) != [str(n) for n in range(1, 12)]:
        print("step-sequence-incomplete")
    for marker in ("## The hard gate", "## Resume", "## Commit guard", "| Step | Requires incoming | Sets |"):
        if marker not in text:
            print("missing-" + marker.strip("# |:").replace(" ", "-").lower())
    required = {"brainstorm", "plan", "execute-tasks", "tdd", "test", "review", "doc-fix", "open-pr", "create-github-issue", "commit"}
    found = set(re.findall(r"dev-flow:([a-z][a-z-]+)", text))
    if required - found:
        print("missing-skill-routes:" + ",".join(sorted(required - found)))
PY
)
if [ -z "$skill_errs" ]; then ok "Codex new-feature skill retains the gated workflow"; else bad "new-feature skill broken:$skill_errs"; fi

# bootstrap wrapper is thin: commands/bootstrap.md exists and carries no
# workflow content — it must point at skills/bootstrap/SKILL.md as the
# single source (same invariant as commands/new-feature.md). The engine,
# not the wrapper, owns the flow.
wrap_errs=""
if [ ! -f "commands/bootstrap.md" ]; then
  wrap_errs="commands/bootstrap.md:missing"
else
  $G -q "skills/bootstrap/SKILL.md" commands/bootstrap.md \
    || wrap_errs="$wrap_errs commands/bootstrap.md:not-thin(no-SKILL-pointer)"
  $G -qE '\$\{?ARGUMENTS\}?' commands/bootstrap.md \
    || wrap_errs="$wrap_errs commands/bootstrap.md:no-arguments-passthrough"
fi
[ -z "$wrap_errs" ] && ok "bootstrap wrapper is thin" || bad "bootstrap wrapper not thin:$wrap_errs"

# new-feature reads the branch config: `.dev-flow/config.json` must be
# mentioned in the new-feature skill — the state file's Base/Target are
# seeded from it when present (feat/55). Guards the config-read wiring.
$G -q "dev-flow/config.json" skills/new-feature/SKILL.md \
  && ok "new-feature mentions branch config" \
  || bad "new-feature skill missing .dev-flow/config.json read"

# branch literals stay out of the branch-deriving skills: create-github-issue
# must not carry a literal `git checkout dev` command (feat/55) — branch names
# derive from the state file / config. Concept grep, not exact sentences.
$G -qE 'checkout (dev|`dev`)' skills/create-github-issue/SKILL.md \
  && bad "create-github-issue still hardcodes a checkout dev command" \
  || ok "create-github-issue derives branch names from the state file"

# open-pr derives --base from the state file's Target branch: the literal
# `--base dev` flag must stay out (feat/55). Concept grep on the flag.
$G -qE -- '--base (dev|`dev`)' skills/open-pr/SKILL.md \
  && bad "open-pr still hardcodes --base dev" \
  || ok "open-pr derives --base from the state file"

# document-structure owns the AGENTS.md entry-point rule (feat/55): the
# engine must carry the entry-point rule — AGENTS.md + CLAUDE.md symlink
# responsibility and the never-gut-content guard — not a bare mention.
ds_errs=""
$G -q 'AGENTS.md' skills/document-structure/SKILL.md || ds_errs="$ds_errs no-AGENTS-md"
$G -q -i 'symlink' skills/document-structure/SKILL.md || ds_errs="$ds_errs no-symlink-rule"
$G -q 'scope boundary' skills/document-structure/SKILL.md || ds_errs="$ds_errs no-boundary-exception-mention"
[ -z "$ds_errs" ] && ok "document-structure owns the AGENTS.md entry-point rule" || bad "entry-point rule missing:$ds_errs"

# must-ask gates are structurally present (issue #67): the three sub-skills
# carry a `## Before starting` read-gate with a stop-and-return consequence,
# new-feature's step 5/6 definitions carry the pre-dispatch ask + write
# (per-step scoping — a whole-file grep would false-positive on keywords
# landing in Resume or notes), and brainstorm carries the Viability pass
# spec-section mandate. Concept grep only, never exact sentences (#38).
gate23_errs=$(python3 -B - <<'PY'
import re
import sys
sys.path.insert(0, "tests/lib")
from sections import section
from pathlib import Path

for rel in ("skills/execute-tasks/SKILL.md", "skills/test/SKILL.md", "skills/review/SKILL.md"):
    try:
        text = Path(rel).read_text()
    except FileNotFoundError:
        print(f"{rel}:missing")
        continue
    body = section(text, "Before starting")
    if not body:
        print(f"{rel}:no-before-starting-block")
        continue
    # stop-and-return consequence, concept-matched (stop + skip reporting)
    if not re.search(r"stop", body) or not re.search(r"report", body):
        print(f"{rel}:no-stop-report-consequence")

nf_path = Path("skills/new-feature/SKILL.md")
try:
    nf = nf_path.read_text()
except FileNotFoundError:
    print("skills/new-feature/SKILL.md:missing")
else:
    step5 = section(nf, "Step 5")
    step6 = section(nf, "Step 6")
    # step 5: combined Roles ask (all three roles, one prompt, before invoking execute-tasks)
    if not re.search(r"[Cc]ombined Roles ask", step5):
        print("new-feature:step5-no-combined-roles-ask")
    if not re.search(r"Implementer.*Tester.*Reviewer", step5, re.S) and not re.search(r"Implementer", step5):
        print("new-feature:step5-missing-role-lines")
    if not re.search(r"[Bb]efore invoking.*execute-tasks", step5):
        print("new-feature:step5-no-before-invoke-rule")
    # step 6: silent read of the Roles block, no orchestrator model ask
    if not re.search(r"[Rr]oles block", step6):
        print("new-feature:step6-no-roles-block-read")
    if not re.search(r"[Nn]o model ask", step6):
        print("new-feature:step6-no-silent-read-rule")

try:
    br = Path("skills/brainstorm/SKILL.md").read_text()
except FileNotFoundError:
    print("skills/brainstorm/SKILL.md:missing")
else:
    # the viability pass must mandate a spec artifact (section-in-spec + approvability), not just the dispatch
    if not re.search(r"[Vv]iability pass.{0,400}section", br, re.S):
        print("brainstorm:no-viability-spec-section-mandate")
    if not re.search(r"not approvable", br):
        print("brainstorm:no-approvability-tie")
PY
)
if [ -z "$gate23_errs" ]; then ok "must-ask gates structurally present (Before starting + step 5/6 pre-dispatch + viability artifact)"; else bad "must-ask gate missing:$gate23_errs"; fi

# risk-tiered review structurally present (issue #71): plan skill requires a
# per-task Risk line (fail-closed, unmarked is not low), new-feature step 7
# carries the pre-invoke risk recheck (escalation-only + waiver recording),
# and review skill carries the focused-reviewer branch with its read-gate
# stops and separate report path. Concept grep only, never exact sentences
# (#38); per-step extraction via the section() helper.
gate24_errs=$(python3 -B - <<'PY'
import re
import sys
sys.path.insert(0, "tests/lib")
from sections import section
from pathlib import Path

try:
    plan = Path("skills/plan/SKILL.md").read_text()
except FileNotFoundError:
    print("skills/plan/SKILL.md:missing")
else:
    # per-task Risk line requirement + unmarked-is-not-low (fail-closed)
    if not re.search(r"Risk line", plan):
        print("plan:no-risk-line-requirement")
    if not re.search(r"unmarked", plan):
        print("plan:no-unmarked-not-low-rule")

try:
    nf = Path("skills/new-feature/SKILL.md").read_text()
except FileNotFoundError:
    print("skills/new-feature/SKILL.md:missing")
else:
    step7 = section(nf, "Step 7")
    # pre-invoke risk recheck + escalation-only combination + waiver recording
    if not re.search(r"[Rr]isk recheck", step7):
        print("new-feature:step7-no-risk-recheck")
    if not re.search(r"escalation-only|never downgrades", step7):
        print("new-feature:step7-no-escalation-only")
    if not re.search(r"waiv", step7):
        print("new-feature:step7-no-waiver-hook")
    # state template carries both new fields
    if not re.search(r"Risk tier", nf) or not re.search(r"Focused verdict", nf):
        print("new-feature:state-template-missing-risk-fields")

try:
    rv = Path("skills/review/SKILL.md").read_text()
except FileNotFoundError:
    print("skills/review/SKILL.md:missing")
else:
    # focused-reviewer section (exact heading — the structural contract)
    if not section(rv, "Focused review"):
        print("review:no-focused-review-section")
    # both read-gate stop concepts (skipped recheck + skipped focused review)
    if not re.search(r"risk recheck was skipped", rv):
        print("review:no-skipped-recheck-stop")
    if not re.search(r"focused review was skipped", rv):
        print("review:no-skipped-focused-stop")
    # separate report path + standalone scope-out
    if not re.search(r"review-report-focused", rv):
        print("review:no-focused-report-path")
    if not re.search(r"[Ss]tandalone.*risk|no tier", rv):
        print("review:no-standalone-scope-out")
PY
)
if [ -z "$gate24_errs" ]; then ok "risk-tiered review structurally present (plan Risk line + step-7 recheck + focused reviewer)"; else bad "risk-tier concept missing:$gate24_errs"; fi
# gate25: model routing — lanes doc, dispatch-skill pointers, combined ask, sandbox/errors
gate25_errs=$(python3 -B - <<'PY'
import re
import sys
sys.path.insert(0, "tests/lib")
from sections import section
from pathlib import Path

rt = "references/model-routing.md"
try:
    text = Path(rt).read_text()
except FileNotFoundError:
    print(f"{rt}:missing")
else:
    # lane grammar keywords + config schema example + resolution rule + sandbox + error contract
    for kw, name in ((r"claude:<name>", "routing:no-claude-lane"),
                     (r"cli:<tool>/<model>", "routing:no-cli-lane"),
                     (r"inline", "routing:no-inline"),
                     (r"session", "routing:no-session"),
                     (r"red-team", "routing:no-red-team")):
        if not re.search(kw, text):
            print(name)
    for head in ("## Lanes", "## Config schema", "## Resolution rule", "## Sandbox map",
                 "## Thin-driver flow", "## Error contract"):
        if section(text, head.strip("# ").strip()) is None:
            print(f"routing:no-{head.strip('#').strip().lower().replace(' ', '-')}-section")
    # a JSON roles example lives on the page (config schema section carries the shape)
    if '"roles"' not in text or '"implementer"' not in text:
        print("routing:no-config-schema-example")
    # stop-and-ask error contract + no-silent-downgrade
    if not re.search(r"stop-and-ask", text):
        print("routing:no-stop-and-ask")
    if not re.search(r"[Nn]o silent downgrade|never a silent downgrade|silent downgrade", text):
        print("routing:no-silent-downgrade-rule")
    # commit ownership: external model prohibited, driver commits via dev-flow:commit
    if not re.search(r"prohibited from committing|never commits", text):
        print("routing:no-commit-ownership")
    # sandbox map: workspace-write + read-only + known network limitation
    if not re.search(r"workspace-write", text) or not re.search(r"read-only", text):
        print("routing:no-sandbox-map-values")
    if not re.search(r"network", text):
        print("routing:no-network-limitation")

for rel in ("skills/execute-tasks/SKILL.md", "skills/test/SKILL.md", "skills/review/SKILL.md",
            "skills/brainstorm/SKILL.md"):
    try:
        text = Path(rel).read_text()
    except FileNotFoundError:
        print(f"{rel}:missing")
        continue
    body = section(text, "Model routing")
    if body is None:
        print(f"{rel}:no-model-routing-section")
        continue
    if "references/model-routing.md" not in body:
        print(f"{rel}:no-routing-doc-pointer")

nf_path = Path("skills/new-feature/SKILL.md")
try:
    nf = nf_path.read_text()
except FileNotFoundError:
    print("skills/new-feature/SKILL.md:missing")
else:
    # Roles template block + combined ask concept
    if not re.search(r"## Roles", nf):
        print("new-feature:no-roles-block")
    if not re.search(r"[Cc]ombined Roles ask", section(nf, "Step 5") or ""):
        print("new-feature:step5-no-combined-roles-ask")
    # steps 6/7 silent: concept-level — no orchestrator model-ask phrase in dev-flow mode.
    # "Verifier model" legitimately survives in upgrade-mapping text; grep the ask phrases.
    for step_no in ("6", "7"):
        step = section(nf, f"Step {step_no}") or ""
        if re.search(r"[Aa]sk the user for the .{0,40}model", step):
            print(f"new-feature:step{step_no}-orchestrator-model-ask-phrase")

# bootstrap covers both ignore lines
try:
    bs = Path("skills/bootstrap/SKILL.md").read_text()
except FileNotFoundError:
    print("skills/bootstrap/SKILL.md:missing")
else:
    if ".dev-flow/" not in bs or "docs/features/" not in bs:
        print("bootstrap:gitignore-coverage-missing")

# gitignore actually carries .dev-flow/
try:
    gi = Path(".gitignore").read_text()
except FileNotFoundError:
    print(".gitignore:missing")
else:
    if not re.search(r"^\.dev-flow/$", gi, re.M):
        print("gitignore:no-dev-flow-line")
PY
)
if [ -z "$gate25_errs" ]; then ok "model routing structurally present (lanes doc + dispatch pointers + combined ask + gitignore)"; else bad "model-routing concept missing:$gate25_errs"; fi
