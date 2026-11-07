# tests/checks/03-skill-contracts.sh — skill-contract check dispatcher.
# Sources concern-grouped fragments in original contract order; cwd is repo root.
for contract_fragment in \
  01-core-workflow \
  02-review-pr \
  03-model-routing \
  04-codex-implementation \
  05-status-prose-and-review-gates \
  06-git-safeguards \
  07-context-efficiency; do
  contract_path="tests/checks/skill-contracts/$contract_fragment.sh"
  [ -f "$contract_path" ] || { echo "FAIL: missing fragment $contract_path"; exit 1; }
  source "$contract_path"
done
