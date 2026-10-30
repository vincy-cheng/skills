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

# document-structure names UI.md as a concern map (#88): the engine must carry
# the UI naming — example tree, filename table, detection evidence, and the
# pointer-first UI-area-table contract — not a bare mention.
ds_errs=""
$G -q 'UI.md' skills/document-structure/SKILL.md || ds_errs="$ds_errs no-UI-md-naming"
$G -q 'UI-area table' skills/document-structure/SKILL.md || ds_errs="$ds_errs no-UI-area-table-contract"
$G -q '.storybook/' skills/document-structure/SKILL.md || ds_errs="$ds_errs no-UI-detection-evidence"
[ -z "$ds_errs" ] && ok "document-structure names UI.md as a concern map" || bad "UI concern map missing:$ds_errs"

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
    if not re.search(r"Implementer", step5) or not re.search(r"Tester", step5) or not re.search(r"Reviewer", step5):
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
    # each lane value must appear as a Lanes-table row (a dropped row fails even
    # if the keyword survives elsewhere in prose — row-anchor, not bare keyword)
    lanes = section(text, "Lanes")
    if not lanes:
        print("routing:no-lanes-section")
    else:
        for lane_kw in ("inline", "session", "claude:<name>", "cli:<tool>/<model>"):
            if not re.search(r"^\|\s*`" + re.escape(lane_kw) + r"`\s*\|", lanes, re.M):
                print(f"routing:lanes-row-missing:{lane_kw}")
    for head in ("## Lanes", "## Config schema", "## Resolution rule", "## Sandbox map",
                 "## Thin-driver flow", "## Error contract"):
        if not section(text, head.strip("# ").strip()):
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
    if not body:
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

# codex-implementer-contract guard (#93, task 1): the routing page owns
# configuration, host scoping, saved selection, and native dispatch/failure rules.

codex_implementer_contract_errs=$(python3 -B - <<'PY'
import re
import sys
sys.path.insert(0, "tests/lib")
from sections import section
from pathlib import Path
rt = Path("references/model-routing.md")
try:
    text = rt.read_text()
except FileNotFoundError:
    print("routing:missing")
    sys.exit(0)
except OSError as error:
    print(f"routing:unreadable:{error}")
    sys.exit(0)
body = section(text, "Codex implementer model")
if not body:
    print("routing:no-codex-implementer-model-section")
    sys.exit(0)
routing_summary = text[:text.find("## Lanes")] if "## Lanes" in text else ""
if "Implementer and tester routing is unchanged." in routing_summary:
    print("routing:implementer-unchanged-summary-stale")
if "codex_implementer_model" not in routing_summary:
    print("routing:implementer-host-aware-summary-missing")
if "codex_implementer_model" not in body or ".dev-flow/config.json" not in body:
    print("routing:implementer-config-missing")
if not re.search(r"host.{0,120}execution path|choose.{0,60}host.{0,120}interpreting", body, re.I):
    print("routing:implementer-host-precedence-missing")
if not re.search(r"Claude Code.{0,300}ignore.{0,240}malformed", body, re.I | re.S):
    print("routing:claude-ignores-malformed-key-missing")
if not re.search(r"tester.{0,240}reviewer.{0,240}unchanged|unchanged.{0,240}tester.{0,240}reviewer", body, re.I | re.S):
    print("routing:test-review-unchanged-missing")
for mode in ("inline", "session", "cli:"):
    if mode not in body:
        print(f"routing:codex-mode-missing:{mode}")
if not re.search(r"native (implementation )?subagent", body, re.I):
    print("routing:no-native-subagent")
if not re.search(r"claude:<name>", body):
    print("routing:no-claude-name-on-codex")
if "Codex implementer model" not in body:
    print("routing:saved-field-missing")
if "Roles" not in body:
    print("routing:saved-field-scope-missing")
if "exact selected model" not in body:
    print("routing:no-exact-selected-model")
for value in ("_(session default)_", "_(not used — inline)_", "_(not used — cli)_"):
    if value not in body:
        print(f"routing:saved-field-value-missing:{value}")
if not re.search(r"missing.{0,200}(older|unconfirmed|not authoriz)", body, re.I):
    print("routing:no-missing-field-rule")
if not re.search(r"legacy.{0,240}(retain|keep).{0,240}mode|mode.{0,240}legacy.{0,240}retain", body, re.I | re.S):
    print("routing:no-legacy-mode-retention")
if not re.search(r"saved.{0,240}selection.{0,240}(surviv|outlast)|surviv.{0,240}later.{0,240}config", body, re.I | re.S):
    print("routing:no-saved-selection-survival")
if not re.search(r"(per-run|confirmed|saved).{0,240}(selection|choice).{0,240}(override|precedence)", body, re.I | re.S):
    print("routing:no-run-choice-precedence")
if not re.search(r"unavailable.{0,200}inactive|inactive.{0,200}unavailable", body, re.I):
    print("routing:no-inavailable-inactive-default-rule")
for failure in ("unreadable", "malformed JSON", "non-object", "schema", "non-string"):
    if not re.search(failure, body, re.I):
        print(f"routing:validation-missing:{failure}")
if not re.search(r"before.{0,300}(availability|tool support|model options|allowlist)", body, re.I | re.S):
    print("routing:no-validate-before-availability")
if not re.search(r"tool support", body, re.I):
    print("routing:no-tool-support-check")
for failure in ("empty", "whitespace"):
    if not re.search(failure, body, re.I):
        print(f"routing:validation-missing:{failure}")
if not re.search(r"trim|hardcode", body, re.I):
    print("routing:no-validation-hygiene")
if not re.search(r"unused|not used", body, re.I):
    print("routing:no-inline-cli-ack")
if not re.search(r"unsupported.{0,200}block", body, re.I):
    print("routing:no-unsupported-mode-block")
if not re.search(r"before every native (implementation )?dispatch", body, re.I):
    print("routing:no-before-dispatch-rule")
if not re.search(r"retry", body, re.I):
    print("routing:no-retry-rule")
if not re.search(r"`model`", body):
    print("routing:no-model-parameter")
if not re.search(r"fork_turns.{0,40}none|fresh.{0,120}context", body, re.I):
    print("routing:no-fresh-context-rule")
if not re.search(r"omit.{0,120}`model`|`model`.{0,120}omit|session default.{0,120}omit", body, re.I):
    print("routing:no-session-default-model-rule")
if not re.search(r"blocked", body, re.I):
    print("routing:no-blocked-consequence")
if not re.search(r"(switch|change).{0,160}(model|mode|lane)", body, re.I):
    print("routing:no-no-switch-rule")
if not re.search(r"change.{0,280}explicit", body, re.I):
    print("routing:no-explicit-change-rule")
PY
)
if [ -z "$codex_implementer_contract_errs" ]; then
  ok "Codex implementer model contract is present with saved-choice precedence"
else
  bad "Codex implementer contract missing:$codex_implementer_contract_errs"
fi

# codex-implementation-integration guard (#93, task 2): the orchestrator owns the
# saved-choice ask/write; execute-tasks owns host-scoped reading/dispatch/retry/report.

codex_implementation_integration_errs=$(python3 -B - <<'PY'
import re
import sys
sys.path.insert(0, "tests/lib")
from sections import section
from pathlib import Path
try:
    nf = Path("skills/new-feature/SKILL.md").read_text()
except FileNotFoundError:
    print("new-feature:missing")
    sys.exit(0)
except OSError as error:
    print(f"new-feature:unreadable:{error}")
    sys.exit(0)
state = section(nf, "State files")
field_rules = nf[nf.index("Field rules:"):nf.index("### Index file")]
step5 = section(nf, "Step 5")
if "**Codex implementer model:**" not in state:
    print("new-feature:state-template-missing-implementer-field")
if not re.search(r"optional.{0,300}omitted until.{0,160}(confirm|choice)|omit.{0,240}until.{0,160}(confirm|choice)", field_rules, re.I | re.S):
    print("new-feature:field-not-optional-until-choice")
if not re.search(r"Codex implementer model.{0,320}outside the Roles block", field_rules, re.S):
    print("new-feature:implementer-field-scope-missing")
if "exact selected model" not in field_rules:
    print("new-feature:no-selected-model-grammar")
for value in ("_(session default)_", "_(not used — inline)_", "_(not used — cli)_"):
    if value not in field_rules and value not in state:
        print(f"new-feature:implementer-value-missing:{value}")
if not re.search(r"missing (field ).{0,220}(legacy|older|unconfirmed)", field_rules, re.I):
    print("new-feature:legacy-implementer-field-rule-missing")
if not re.search(r"change.{0,260}explicit", field_rules, re.I):
    print("new-feature:implementer-change-rule-missing")
if "references/model-routing.md" not in field_rules and "references/model-routing.md" not in state:
    print("new-feature:implementation-routing-pointer-missing")
if not re.search(r"[Cc]ombined Roles ask", step5):
    print("new-feature:step5-no-combined-roles-ask")
if "codex_implementer_model" not in step5:
    print("new-feature:step5-no-implementer-config")
if not re.search(r"validation contract|Codex implementer model contract", step5):
    print("new-feature:step5-no-validation-contract")
if not re.search(r"before.{0,240}task work", step5, re.I | re.S):
    print("new-feature:step5-no-before-task-work")
if not re.search(r"execution mode.{0,160}model|model.{0,160}execution mode", step5, re.I):
    print("new-feature:step5-no-mode-model-pair")
if not re.search(r"native (implementation )?subagent", step5, re.I):
    print("new-feature:step5-no-native-subagent")
if not re.search(r"roles.implementer", step5, re.I):
    print("new-feature:step5-no-conflicting-mode-handling")
if not re.search(r"prefill", step5, re.I):
    print("new-feature:step5-no-prefill")
if not re.search(r"confirm", step5, re.I):
    print("new-feature:step5-no-confirmation")
if not re.search(r"silent", step5, re.I):
    print("new-feature:step5-no-no-silent-switch-rule")
if not re.search(r"unused", step5, re.I):
    print("new-feature:step5-no-unused-ack")
if not re.search(r"Tester", step5) or not re.search(r"Reviewer", step5):
    print("new-feature:step5-no-all-roles-pair")
try:
    et = Path("skills/execute-tasks/SKILL.md").read_text()
except FileNotFoundError:
    print("execute-tasks:missing")
    sys.exit(0)
except OSError as error:
    print(f"execute-tasks:unreadable:{error}")
    sys.exit(0)
gate = section(et, "Gate")
before = section(et, "Before starting")
choose = section(et, "Choose a mode")
routing = section(et, "Model routing")
dispatch = section(et, "Subagent dispatch — per-task loop")
state_updates = section(et, "Shared: state-file updates")
if "`issue`" not in gate:
    print("execute-tasks:gate-no-issue-entry")
if "`execute`" not in gate or not re.search(r"re-entry|already", gate, re.I):
    print("execute-tasks:gate-no-execute-reentry")
if not re.search(r"branch.{0,160}Base branch", gate, re.I):
    print("execute-tasks:gate-no-branch-check")
if not re.search(r"On Claude Code.{0,360}ignore", before, re.I | re.S):
    print("execute-tasks:no-claude-host-ignore")
if not re.search(r"malformed.{0,240}codex|malformed.{0,240}implementer|codex_implementer_model.{0,240}malformed", before, re.I | re.S):
    print("execute-tasks:no-claude-malformed-key-ignore")
if not re.search(r"On Codex.{0,360}read.{0,240}Codex implementer model", before, re.I | re.S):
    print("execute-tasks:codex-only-choice-read-missing")
if not re.search(r"re-ask", before):
    print("execute-tasks:no-confirmed-no-reask-rule")
if not re.search(r"missing.{0,300}(legacy|older|unconfirmed)|legacy", before, re.I):
    print("execute-tasks:no-legacy-field-rule")
if not re.search(r"block.{0,180}task work", before, re.I):
    print("execute-tasks:no-malformed-state-block")
if "codex_implementer_model" not in choose:
    print("execute-tasks:standalone-no-implementer-config")
if not re.search(r"equivalent", choose, re.I):
    print("execute-tasks:standalone-not-equivalent")
if not re.search(r"retain|throughout", choose, re.I):
    print("execute-tasks:standalone-no-choice-retention")
if not re.search(r"native", choose, re.I):
    print("execute-tasks:standalone-no-native-option")
if "Codex implementer model" not in routing:
    print("execute-tasks:routing-no-implementer-contract")
if not re.search(r"shared contract", routing, re.I):
    print("execute-tasks:routing-no-shared-contract")
if not re.search(r"native.{0,160}Claude|Claude.{0,160}native|separate", routing, re.I):
    print("execute-tasks:routing-no-host-separation")
if not re.search(r"native.{0,360}(Claude Code|claude|CLI)", routing, re.I | re.S):
    print("execute-tasks:routing-no-native-only-scope")
if not re.search(r"self-review", routing, re.I):
    print("execute-tasks:routing-no-self-review")
if not re.search(r"commit ownership|never commits|commits via", routing, re.I):
    print("execute-tasks:routing-no-commit-ownership")
if not re.search(r"one implementer|Never dispatch more than one", dispatch, re.I):
    print("execute-tasks:dispatch-not-serial")
if not re.search(r"fresh|brief", dispatch, re.I):
    print("execute-tasks:dispatch-no-fresh-brief")
if "Execution model" not in dispatch:
    print("execute-tasks:report-no-execution-model")
if not re.search(r"session-default|session default", dispatch, re.I):
    print("execute-tasks:report-no-session-default")
if not re.search(r"backend identifier", dispatch, re.I):
    print("execute-tasks:report-no-backend-honesty")
if "NEEDS_CONTEXT" not in dispatch:
    print("execute-tasks:retry-status-missing")
if not re.search(r"retry.{0,240}(same|retain|unchanged|pinned)|pinned.{0,200}(unchanged|same|explicit)", dispatch, re.I):
    print("execute-tasks:retry-model-preservation-missing")
if not re.search(r"native.{0,360}(Claude Code|claude|CLI)|Claude Code.{0,360}(existing|unchanged)", dispatch, re.I | re.S):
    print("execute-tasks:retry-native-vs-existing-model-rule-missing")
if not re.search(r"explicit", dispatch, re.I):
    print("execute-tasks:retry-explicit-change-rule-missing")
if "inline" not in state_updates or "provenance" not in state_updates:
    print("execute-tasks:inline-provenance-missing")
if not re.search(r"Last verification", state_updates):
    print("execute-tasks:state-updates-no-verification")
PY
)
if [ -z "$codex_implementation_integration_errs" ]; then
  ok "Codex implementation-model integration is present with host-scoped retries"
else
  bad "Codex implementation integration missing:$codex_implementation_integration_errs"
fi

# gate28: Codex implementation-model documentation (#93). README owns the
# user-facing configuration explanation; bootstrap owns preserving user choices
# and leaving both native overrides absent by default; agent-facing summaries
# keep the host/state maps current. Concept greps only, never sentence freezing.
gate28_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

readme = Path("README.md")
try:
    readme_text = readme.read_text()
except FileNotFoundError:
    print("README.md:missing")
    readme_text = ""
except OSError as error:
    print(f"README.md:unreadable:{error}")
    readme_text = ""

config_blocks = re.findall(r"```json\s*(.*?)```", readme_text, re.S)
if not any('"codex_implementer_model"' in block and '"codex_reviewer_model"' in block
           for block in config_blocks):
    print("readme:no-both-native-config-example")
if not re.search(r"inline.{0,240}session model|session model.{0,240}inline", readme_text, re.I | re.S):
    print("readme:no-inline-session-model-rule")
if not re.search(r"native.{0,240}subagent|subagent.{0,240}native", readme_text, re.I | re.S):
    print("readme:no-native-subagent-mode-rule")
if not re.search(r"saved.{0,160}resume|resume.{0,160}saved", readme_text, re.I | re.S):
    print("readme:no-saved-resume-rule")
if not re.search(r"unavailable.{0,240}block|block.{0,240}unavailable", readme_text, re.I | re.S):
    print("readme:no-failure-behavior")
if not re.search(r"roles\.implementer", readme_text):
    print("readme:no-claude-implementer-equivalent")
if not re.search(r"CLI.{0,240}unchanged|unchanged.{0,240}CLI", readme_text, re.I | re.S):
    print("readme:no-cli-unchanged-rule")

bootstrap = Path("skills/bootstrap/SKILL.md")
try:
    bootstrap_text = bootstrap.read_text()
except FileNotFoundError:
    print("skills/bootstrap/SKILL.md:missing")
    bootstrap_text = ""
except OSError as error:
    print(f"skills/bootstrap/SKILL.md:unreadable:{error}")
    bootstrap_text = ""
branch_config = re.search(r"^### 3\. Branch config\n(.*?)(?=^### |\Z)", bootstrap_text, re.M | re.S)
bootstrap_config = branch_config[1] if branch_config else ""
for key in ("codex_reviewer_model", "codex_implementer_model"):
    if key not in bootstrap_config:
        print(f"bootstrap:{key}-not-preserved")
if not re.search(r"preserve.{0,360}(codex_reviewer_model|both.{0,80}native|codex_implementer_model)", bootstrap_config, re.I | re.S):
    print("bootstrap:no-preserve-native-overrides")
default_blocks = re.findall(r"```json\s*(.*?)```", bootstrap_config, re.S)
if any('"codex_reviewer_model"' in block or '"codex_implementer_model"' in block
       for block in default_blocks):
    print("bootstrap:native-model-pinned-by-default")
if not re.search("choose a model|never choose a model", bootstrap_config, re.I):
    print("bootstrap:no-no-model-choice-rule")

agents = Path("AGENTS.md")
try:
    agents_text = agents.read_text()
except (FileNotFoundError, OSError):
    print("AGENTS.md:unreadable-or-missing")
    agents_text = ""
if "codex_implementer_model" not in agents_text:
    print("agents:no-implementer-key-summary")

architecture = Path("docs/agents/ARCHITECTURE.md")
try:
    architecture_text = architecture.read_text()
except (FileNotFoundError, OSError):
    print("docs/agents/ARCHITECTURE.md:unreadable-or-missing")
    architecture_text = ""
for marker in ("codex_reviewer_model", "codex_implementer_model", "Codex implementer model"):
    if marker not in architecture_text:
        print(f"architecture:missing-{marker}")

devops = Path("docs/agents/DEVOPS.md")
try:
    devops_text = devops.read_text()
except (FileNotFoundError, OSError):
    print("docs/agents/DEVOPS.md:unreadable-or-missing")
    devops_text = ""
for marker in ("codex_reviewer_model", "codex_implementer_model"):
    if marker not in devops_text:
        print(f"devops:missing-{marker}")
if not re.search(r"preserve.{0,320}codex_(?:reviewer|implementer)_model", devops_text, re.I | re.S):
    print("devops:no-preserve-native-overrides")
PY
)
if [ -z "$gate28_errs" ]; then ok "Codex implementation-model documentation is present"; else bad "Codex implementation documentation missing:$gate28_errs"; fi

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
    "current-availability": r"current.*(?:options|allowlist)",
    "before-every-dispatch": r"[Bb]efore every.*dispatch",
    "blocked": r"BLOCKED.*(?:no|zero).*dispatch",
    "codex-ignores-roles": r"Codex.*ignore.*`roles`",
    "claude-ignores-key": r"Claude Code.*ignore.*`codex_reviewer_model`",
}
for name, pattern in checks.items():
    if not re.search(pattern, codex, re.S):
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
