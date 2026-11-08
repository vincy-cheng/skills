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

# implementer-context integration guard (#108, task 2): new-feature owns the
# state template field + field rules + the step-5 ask covering all four picks;
# unknown values block; saved choices survive; legacy state stays per-task.
implementer_context_integration_errs=$(python3 -B - <<'PY'
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
state_body = section(nf.replace("### Per-feature state file", "## Per-feature state file"), "Per-feature state file") if False else ""
# the state template carries the field next to Codex implementer model
tmpl = nf[nf.index("# <feat-name> — dev-flow state"):nf.index("Field rules:")]
if "- **Implementer context:**" not in tmpl:
    print("new-feature:state-template-missing-context-field")
if not re.search(r"Implementer context.{0,400}(shared \| per-task \| not-used|shared/per-?task/not-used)", tmpl, re.S):
    print("new-feature:context-field-no-value-grammar")
# field rules: confirmed choice recorded; legacy subagent runs = per-task; unknown stops
if not re.search(r"[Ii]mplementer context.{0,240}optional", field_rules, re.I | re.S):
    print("new-feature:context-field-not-optional-rule")
if not re.search(r"per-?task.{0,400}(?:legacy|older)|(?:legacy|older).{0,400}per-?task", field_rules, re.I | re.S):
    print("new-feature:context-no-legacy-per-task-rule")
if not re.search(r"[Uu]nknown.{0,240}stop|stop.{0,240}unknown", field_rules, re.I):
    print("new-feature:context-unknown-stops-rule")
if not re.search(r"[Ss]aved.{0,200}prefer|prefer.{0,200}saved", field_rules, re.I):
    print("new-feature:context-no-saved-preference-rule")
if not re.search(r"resume.{0,300}repair|repair.{0,300}resume", field_rules, re.I | re.S):
    print("new-feature:context-no-resume-repair-rule")
if not re.search(r"shared contract|references/model-routing.md", field_rules):
    print("new-feature:context-no-routing-pointer")
# step 5: the combined ask now covers lane + model + context lifecycle together
if not re.search(r"[Cc]ombined Roles ask", step5):
    print("new-feature:context-step5-no-combined-ask")
if not re.search(r"[Ii]mplementer context", step5):
    print("new-feature:context-step5-no-context-pick")
if not re.search(r"shared.{0,300}per-?task.{0,300}not-used|not-used.{0,300}per-?task.{0,300}shared", step5, re.I | re.S):
    print("new-feature:context-step5-no-value-choices")
if not re.search(r"(?:trade-?offs?|recommend)", step5, re.I):
    print("new-feature:context-step5-no-tradeoffs")
if not re.search(r"(?:never|not).{0,240}(?:choose|pick|select|switch).{0,240}model|no silent", step5, re.I):
    print("new-feature:context-step5-no-no-silent-model-pick")
PY
)
if [ -z "$implementer_context_integration_errs" ]; then
  ok "Implementer context state field and combined-ask integration are present"
else
  bad "Implementer context integration missing:$implementer_context_integration_errs"
fi

# implementer-context execution guard (#108, task 3): execute-tasks owns the
# shared-worker loop — first dispatch starts the worker, later tasks follow up
# with the same worker; live recheck per follow-up; stop/handoff on context
# overflow, lost worker, boundary change; single writer; report/diff preservation.
implementer_context_execution_errs=$(python3 -B - <<'PY'
import re
import sys
sys.path.insert(0, "tests/lib")
from sections import section
from pathlib import Path
try:
    et = Path("skills/execute-tasks/SKILL.md").read_text()
except FileNotFoundError:
    print("execute-tasks:missing")
    sys.exit(0)
except OSError as error:
    print(f"execute-tasks:unreadable:{error}")
    sys.exit(0)
dispatch = section(et, "Subagent dispatch — per-task loop")
stuck = section(et, "When a task gets stuck")
after = section(et, "After all tasks")
wntd = section(et, "What not to do")
if not re.search(r"[Ss]hared.{0,160}(?:worker|context)|shared context lifecycle", dispatch, re.I):
    print("execute-tasks:dispatch-no-shared-shape")
if not re.search(r"follow-?up.{0,400}same (?:worker|implementer)|same (?:worker|implementer).{0,400}follow-?up", dispatch, re.I | re.S):
    print("execute-tasks:dispatch-no-same-worker-followup")
if not re.search(r"one task at a time|one at a time", dispatch, re.I):
    print("execute-tasks:dispatch-no-one-task-at-a-time")
if "brief" not in dispatch or "report" not in dispatch:
    print("execute-tasks:dispatch-no-brief-report-per-task")
if "TDD" not in dispatch:
    print("execute-tasks:dispatch-no-tdd-per-task")
if not re.search(r"recheck.{0,400}(branch|HEAD|dirty)|branch.{0,200}HEAD.{0,200}dirty", dispatch, re.I | re.S):
    print("execute-tasks:dispatch-no-live-recheck")
if not re.search(r"not.{0,200}resend.{0,200}(?:whole|entire).{0,200}conversation|no.{0,200}full.{0,200}resend|[Dd]o not (?:re-?send|repeat).{0,240}unchanged", dispatch, re.I):
    print("execute-tasks:dispatch-no-full-resend-rule")
if not re.search(r"reload.{0,240}(?:changed|can'?t confirm|unconfirmed)|(?:changed|stale).{0,240}reload", dispatch, re.I):
    print("execute-tasks:dispatch-no-changed-reload")
if not re.search(r"coordinator.{0,200}check", dispatch, re.I):
    print("execute-tasks:dispatch-no-coordinator-check")
if not re.search(r"(?:context|conversation).{0,240}(?:too long|overflow|grows)|[Ll]ost worker|worker.{0,160}lost", dispatch + stuck, re.I | re.S):
    print("execute-tasks:no-context-overflow-handoff")
if not re.search(r"save.{0,200}(?:report|diff|findings)|(?:report|diff).{0,200}(?:before|preserv)", dispatch + stuck, re.I | re.S):
    print("execute-tasks:no-preserve-before-switch")
if not re.search(r"explicit.{0,240}confirm.{0,320}(?:switch|new worker|other mode)|ask.{0,200}before.{0,200}switch", dispatch + stuck, re.I | re.S):
    print("execute-tasks:no-confirmed-switch")
if not re.search(r"[Ss]ingle writer|only one writer", dispatch + wntd, re.I):
    print("execute-tasks:no-single-writer-rule")
if not re.search(r"resume.{0,320}repair.{0,320}worker|worker.{0,320}(?:resume|repair)", et, re.I | re.S):
    print("execute-tasks:no-resume-worker-recheck")
if not re.search(r"(?:not|never).{0,240}claim.{0,240}(?:old conversation|worker)|can'?t (?:recover|restore)", et, re.I):
    print("execute-tasks:no-false-continuity-claim")
if not re.search(r"(?:cited|referenced|referenced by).{0,400}stays?|stays?.{0,240}cited|report.{0,320}(?:still )?cited", after, re.I | re.S):
    print("execute-tasks:after-all-no-report-retention")
PY
)
if [ -z "$implementer_context_execution_errs" ]; then
  ok "Shared implementer execution loop and recovery contract are present"
else
  bad "Implementer context execution contract missing:$implementer_context_execution_errs"
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
