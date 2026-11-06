# tests/checks/skill-contracts/03-model-routing.sh — model routing contract checks.
# Sourced by tests/checks/03-skill-contracts.sh; cwd is repo root.

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
if "Native model validation" not in body:
    print("routing:no-shared-native-validation-pointer")
if not re.search(r"tool support|string-parameter support", body, re.I):
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
