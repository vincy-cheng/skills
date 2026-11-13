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

# Plugin-root reference resolution must be explicit from portable skill bases,
# and the Claude command wrapper must point at its engine without duplicating it.
source_pointer_errs=$(python3 -B - <<'PY'
from pathlib import Path
import re
review = Path("skills/review/SKILL.md").read_text()
feature = Path("skills/new-feature/SKILL.md").read_text()
wrapper = Path("commands/new-feature.md").read_text()
case12 = Path("evals/model-routing/cases/12-reviewer-group-rework/graders/grader.md").read_text()
for name, text in (("review", review), ("new-feature", feature)):
    for target in ("../../references/model-routing.md", "../../references/output-style.md"):
        if target not in text:
            print(f"{name}:missing-plugin-root-link:{target}")
        elif not (Path("skills") / name / target).resolve().is_file():
            print(f"{name}:dangling-plugin-root-link:{target}")
if "[skills/new-feature/SKILL.md](../skills/new-feature/SKILL.md)" not in wrapper:
    print("new-feature-wrapper:missing-portable-relative-engine-link")
if "${CLAUDE_PLUGIN_ROOT}" in wrapper:
    print("new-feature-wrapper:requires-claude-plugin-root")
if not (Path("commands") / "../skills/new-feature/SKILL.md").resolve().is_file():
    print("new-feature-wrapper:dangling-engine-link")
if not re.search(r"already exhausted.*cap.*stop.*without another dispatch", case12, re.I | re.S):
    print("case12:exhausted-cap-expectation-is-ambiguous")
PY
)
[ -z "$source_pointer_errs" ] && ok "plugin-root source pointers and exhausted-cap grader expectation are explicit" || bad "source-resolution/eval contract missing:$source_pointer_errs"

# codex-implementer-contract guard (#93, task 1): the routing page owns
# configuration, host scoping, saved selection, and native dispatch/failure rules.

codex_implementer_contract_errs=$(python3 -B - <<'PY'
import re
import sys
import atexit, traceback as _tb
def _uncaught(tp, val, tb):
    print('py-guard-crashed:' + ''.join(_tb.format_exception(tp, val, tb)).replace(chr(10), ' | ').strip())
    atexit.register(lambda: None)
    raise SystemExit(1)
sys.excepthook = _uncaught

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
codex_implementer_contract_errs_rc=$? 2>/dev/null || true
[ -n "$codex_implementer_contract_errs_rc" ] && [ "$codex_implementer_contract_errs_rc" != "0" ] && codex_implementer_contract_errs="$codex_implementer_contract_errs py-guard-crashed"
if [ -z "$codex_implementer_contract_errs" ]; then
  ok "Codex implementer model contract is present with saved-choice precedence"
else
  bad "Codex implementer contract missing:$codex_implementer_contract_errs"
fi

# implementer-context guard (#108, task 2): the routing page owns the context
# lifecycle — lane/model/context are separate picks confirmed together; the
# state field's grammar, legacy per-task default, saved-choice precedence,
# host capability verification and stop rules live there.
implementer_context_errs=$(python3 -B - <<'PY'
import re
import sys
import atexit, traceback as _tb
def _uncaught(tp, val, tb):
    print('py-guard-crashed:' + ''.join(_tb.format_exception(tp, val, tb)).replace(chr(10), ' | ').strip())
    atexit.register(lambda: None)
    raise SystemExit(1)
sys.excepthook = _uncaught

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
body = section(text, "Implementer context")
if not body:
    print("routing:no-implementer-context-section")
    sys.exit(0)
for value in ("shared", "per-task", "not-used"):
    if value not in body:
        print(f"routing:context-value-missing:{value}")
# lane, model, context lifecycle are separate selections confirmed in one ask
if not re.search(r"[Ss]eparate.{0,240}(?:pick|selection|select)|(?:pick|selection).{0,240}separate", body, re.I | re.S):
    print("routing:context-no-separate-selection")
# confirmed together in the existing combined Roles ask; no new config frame
if not re.search(r"[Cc]ombined Roles ask|combined ask", body, re.I):
    print("routing:context-not-in-combined-ask")
if not re.search(r"no (?:new |additional )?(?:config|settings?|lane)", body, re.I):
    print("routing:context-no-new-config")
# legacy/missing field keeps per-task for old subagent runs
if not re.search(r"[Mm]issing.{0,240}(?:legacy|older|old).{0,240}per-?task|per-?task.{0,240}(?:legacy|older|old)", body, re.I | re.S):
    print("routing:context-no-legacy-per-task-default")
# unknown value stops, never treated as unselected/unset
if not re.search(r"[Uu]nknown.{0,160}stop|stop.{0,160}unknown", body, re.I):
    print("routing:context-no-unknown-stops")
# saved choice beats new config; resume/repair never re-ask
if not re.search(r"[Ss]aved.{0,240}(?:choice|pick).{0,240}(?:beats?|precede|override|wins?|precedence)", body, re.I | re.S):
    print("routing:context-no-saved-choice-precedence")
if not re.search(r"resume.{0,240}repair.{0,240}re-ask|repair.{0,240}resume.{0,240}re-ask|(?:resume|repair).{0,240}not.{0,80}re-ask|re-ask.{0,160}(?:resume|repair)", body, re.I | re.S):
    print("routing:context-no-resume-no-reask")
# host capability verified before shared starts; each host judged by actual tooling
if not re.search(r"follow-?up.{0,320}resume|resume.{0,320}follow-?up", body, re.I | re.S):
    print("routing:context-no-worker-followup-resume-check")
if "not-used" in body and not re.search(r"[Ii]nline.{0,240}not-used|not-used.{0,240}inline", body, re.I | re.S):
    print("routing:context-no-inline-notused")
# capability gap → enumerate explicit alternatives, never downgrade silently
if not re.search(r"[Ss]top.{0,320}(?:list|enumerat|per-?task)|(?:per-?task|alternativ).{0,320}explicit.{0,120}choos", body, re.I | re.S):
    print("routing:context-no-capability-gap-stop")
# CLI re-run with same model is NOT shared; no-switch rules survive
if not re.search(r"CLI.{0,320}(?:re-?run|rerun|per-?task)|re-?run.{0,320}not.{0,80}shared", body, re.I | re.S):
    print("routing:context-no-cli-not-shared")
if not re.search(r"no-switch|not.{0,40}switch", body, re.I):
    print("routing:context-no-switch-rule-missing")
# recommendations: lightweight-model+related → shared; no model difference+tight → inline; isolation → per-task
if not re.search(r"lightweight.{0,400}shared|shared.{0,400}lightweight", body, re.I | re.S):
    print("routing:context-no-lightweight-shared-rec")
if not re.search(r"inline.{0,400}(?:tightly?.{0,40}coupled|no.{0,40}differ(?:ent|ent) model)", body, re.I | re.S):
    print("routing:context-no-inline-rec")
if not re.search(r"isolation.{0,400}per-?task|per-?task.{0,400}isolation", body, re.I | re.S):
    print("routing:context-no-pertask-isolation-rec")
# fresh-context rules scoped to per-task/new-worker first dispatch
if not re.search(r"fresh.{0,240}context.{0,400}per-?task|per-?task.{0,200}fresh.{0,240}context", body, re.I | re.S):
    print("routing:context-no-fresh-context-scoping")
PY
)
implementer_context_errs_rc=$? 2>/dev/null || true
[ -n "$implementer_context_errs_rc" ] && [ "$implementer_context_errs_rc" != "0" ] && implementer_context_errs="$implementer_context_errs py-guard-crashed"
if [ -z "$implementer_context_errs" ]; then
  ok "Implementer context lifecycle contract is present with host capability gates"
else
  bad "Implementer context contract missing:$implementer_context_errs"
fi

# multi-model-reviewers task 1: shared reviewer-list and batch contract.
reviewer_batch_errs=$(python3 -B - <<'PY'
import re
import sys
from pathlib import Path

sys.path.insert(0, "tests/lib")
from sections import section

text = Path("references/model-routing.md").read_text()
body = section(text, "Per-step reviewer groups") or ""
for key in ("codex_reviewers", "reviewers"):
    if key not in body:
        print(f"reviewers:missing-map:{key}")
for step in ("red_team", "plan_review", "main_review", "focused_review"):
    if step not in body:
        print(f"reviewers:missing-step:{step}")
if not re.search(r"list.{0,100}overrides.{0,100}step|override.{0,160}existing", body, re.I | re.S):
    print("reviewers:missing-override-precedence")
for term in ("Codex uses", "ignores", "state-file picks", "standalone asks", "codex_reviewer_model", "Claude Code", "unavailable", "active-host", "exact duplicate", "nonempty array", "invalid lanes"):
    if term.lower() not in body.lower():
        print(f"reviewers:selection-or-validation-missing:{term}")
if not re.search(r"Native model validation", body):
    print("reviewers:no-native-validation-pointer")
if not re.search(r"before each queued dispatch", body):
    print("reviewers:no-queued-availability-check")

batches = section(text, "Review batches") or ""
for term in ("fresh independent context", "available host slots", "never exceed host concurrency", "complete reviewed diff", "uncommitted changes", "substantive change invalidates", "read-only sandbox", "verbatim", "reviewer-<I>", "reviewer-<I>.md", "one-based", "fresh complete batch", "FUNDAMENTAL", "adjudication", "unanimous approval"):
    if term.lower() not in batches.lower():
        print(f"reviewers:batch-contract-missing:{term}")
if not re.search(r"(?:every|all) members? must return", batches, re.I):
    print("reviewers:missing-complete-member-reports")
if not re.search(r"pass sections only after this acceptance check", batches):
    print("reviewers:missing-acceptance-before-pass-record")
PY
)
if [ -z "$reviewer_batch_errs" ]; then ok "per-step reviewer maps and precedence are documented"; else bad "reviewer-list contract missing:$reviewer_batch_errs"; fi

# Task 5 (#100): public config example and bootstrap preservation contract.
reviewer_docs_errs=$(python3 -B - <<'PY'
import json
import re
from pathlib import Path

readme = Path("README.md").read_text()
bootstrap = Path("skills/bootstrap/SKILL.md").read_text()
example = re.search(r"### Per-step reviewer groups.*?```json\s*(.*?)```", readme, re.S)
if not example:
    print("reviewer-docs:no-per-step-json-example")
else:
    try:
        config = json.loads(example.group(1))
    except json.JSONDecodeError:
        print("reviewer-docs:invalid-json-example")
    else:
        keys = ("red_team", "plan_review", "focused_review")
        expected_counts = {"red_team": 2, "plan_review": 1, "focused_review": 2}
        for host_map in ("codex_reviewers", "reviewers"):
            routes = config.get(host_map, {})
            if not isinstance(routes, dict) or set(routes) != set(keys):
                print(f"reviewer-docs:incomplete-map:{host_map}")
            for step, count in expected_counts.items():
                if not isinstance(routes.get(step), list) or len(routes[step]) != count:
                    print(f"reviewer-docs:wrong-count:{host_map}:{step}")
if not re.search(r"bootstrap.{0,160}(?:preserv|keep).{0,160}codex_reviewers", readme, re.I | re.S):
    print("reviewer-docs:readme-no-bootstrap-preservation")
if not re.search(r"preserv.{0,180}(?:codex_reviewers|reviewers).{0,180}(?:existing|other|unrelated).{0,180}key", bootstrap, re.I | re.S):
    print("reviewer-docs:bootstrap-no-map-preservation")
default_config = re.search(r"```json\s*(.*?)```", bootstrap, re.S)
if default_config and any(key in default_config.group(1) for key in ('"codex_reviewers"', '"reviewers"')):
    print("reviewer-docs:optional-map-in-default-config")
for key in ("codex_reviewers", "reviewers"):
    if key not in bootstrap:
        print(f"reviewer-docs:bootstrap-missing:{key}")
PY
)
[ -z "$reviewer_docs_errs" ] && ok "reviewer config example and bootstrap preservation are documented" || bad "reviewer docs contract missing:$reviewer_docs_errs"
