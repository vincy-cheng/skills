# tests/checks/03-skill-contracts.sh — skill-contract check dispatcher.
# Sources concern-grouped fragments in original contract order; cwd is repo root.
for contract_fragment in \
  01-core-workflow \
  02-review-pr \
  03-model-routing \
  04-codex-implementation \
  05-status-prose-and-review-gates \
  06-git-safeguards \
  07-context-efficiency \
  08-task-outcomes; do
  contract_path="tests/checks/skill-contracts/$contract_fragment.sh"
  [ -f "$contract_path" ] || { echo "FAIL: missing fragment $contract_path"; exit 1; }
  source "$contract_path"
done

# The run index links each feat name to its sibling state file, and Resume
# follows valid links directly before falling back to index recovery.
index_link_errs=$(python3 -B - <<'PY'
import re
from pathlib import Path

text = Path("skills/new-feature/SKILL.md").read_text()
template = text.split("### Index file", 1)[1].split("## Resume", 1)[0]
resume = text.split("## Resume", 1)[1].split("## Preflight", 1)[0]
if not re.search(r"\| \[<feat-name>\]\(<feat-name>\.state\.md\) \|", template):
    print("index-template-no-relative-state-link")
if not re.search(r"open the linked state file directly", resume, re.I):
    print("resume-does-not-open-linked-state-file")
PY
)
[ -z "$index_link_errs" ] && ok "run index links names to sibling state files" || bad "run index links missing:$index_link_errs"
