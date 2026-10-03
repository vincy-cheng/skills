#!/usr/bin/env bash
# tests/check-refs.sh — assertions for the move-cost-spec-to-reference run (issue #40).
# Verifies the two skill extractions landed: reference files exist with their content
# intact, SKILL.md files carry the conditional-load pointers, and new-idea actually
# shrank. Disposable for the red-green loop; exit 0 = all assertions pass.
set -u
cd "$(dirname "$0")/.."
G=/usr/bin/grep

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1"; }

# --- cost.md extraction (new-idea) ---
COST_REF=dev-flow/skills/new-idea/references/cost.md
COST_SKILL=dev-flow/skills/new-idea/SKILL.md

# 1. reference file exists
[ -f "$COST_REF" ] && ok "cost-ref-exists" || bad "cost-ref-exists"

# 2. moved content survives (distinguishing phrases from the original block)
for phrase in "usage-spend" "Full-stack coverage" "Show the calculation" "vendor.com/pricing"; do
  $G -q "$phrase" "$COST_REF" 2>/dev/null && ok "cost-ref-content:$phrase" || bad "cost-ref-content:$phrase"
done

# 3. SKILL.md keeps the summary + conditional-load pointer
$G -q "references/cost.md" "$COST_SKILL" && ok "cost-pointer-exists" || bad "cost-pointer-exists"
$G -q "load \`references/cost.md\`" "$COST_SKILL" && ok "cost-pointer-wording" || bad "cost-pointer-wording"

# 4. the big section body is gone from SKILL.md (heading stays as the summary's title)
$G -q "Verify before writing, ask when you can't" "$COST_SKILL" && bad "cost-body-removed" || ok "cost-body-removed"

# 5. new-idea SKILL.md shrank to the ~60-lines-lighter target (229 baseline)
if [ -f "$COST_SKILL" ]; then
  lines=$($G -c "" "$COST_SKILL")
  [ "$lines" -le 195 ] && ok "cost-skill-shrunk:$lines" || bad "cost-skill-shrunk:$lines (expected <=195)"
  [ "$lines" -ge 183 ] && ok "cost-skill-not-over-trimmed:$lines" || bad "cost-skill-not-over-trimmed:$lines (expected >=183)"
else
  bad "cost-skill-shrunk:skill-missing"
fi

# --- mermaid.md extraction (document-structure) ---
MM_REF=dev-flow/skills/document-structure/references/mermaid.md
MM_SKILL=dev-flow/skills/document-structure/SKILL.md

# 6. reference file exists
[ -f "$MM_REF" ] && ok "mermaid-ref-exists" || bad "mermaid-ref-exists"

# 7. moved content survives
for phrase in "box-drawing" "subgraph" "accurate before pretty" "docs/agents/"; do
  $G -q "$phrase" "$MM_REF" 2>/dev/null && ok "mermaid-ref-content:$phrase" || bad "mermaid-ref-content:$phrase"
done

# 8. SKILL.md keeps the one-line rule + pointer, mega-paragraph gone
$G -q "references/mermaid.md" "$MM_SKILL" && ok "mermaid-pointer-exists" || bad "mermaid-pointer-exists"
$G -q "Mermaid is for files humans will open" "$MM_SKILL" && ok "mermaid-rule-line" || bad "mermaid-rule-line"
$G -q "Mermaid renders in chat" "$MM_SKILL" && bad "mermaid-paragraph-removed" || ok "mermaid-paragraph-removed"

echo "---"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]