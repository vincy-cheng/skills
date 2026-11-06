# tests/checks/skill-contracts/04-codex-implementation.sh — Codex implementation contract checks.
# Sourced by tests/checks/03-skill-contracts.sh; cwd is repo root.

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
