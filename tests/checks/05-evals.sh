# tests/checks/05-evals.sh — eval case.yaml schema invariants.
# sourced by tests/check.sh; cwd is repo root.

# eval case.yaml schema invariants (silent-failure guards, learned the hard way):
#     a) turn/timeout settings must nest under `execution:` — top-level they are
#        silently ignored and runs die at the default 10 turns;
#     b) an explicit llm grader's `criteria:` is passed to the judge VERBATIM — a bare
#        file path is never resolved, so that grader scores on the string "graders/grader.md"
#        instead of the file (auto-discovered graders/*.md files do carry real content);
#     c) every referenced graders/*.md must exist (case dir first, then suite dir —
#        the legacy suites keep graders at suite level);
#     d) legacy fields (`grader:`, `extra_checks:`, `skill:`) are rejected by the
#        current CLI's strict schema — old-format cases can't run at all.
ev_errs=""
for f in evals/*/cases/*/case.yaml; do
  dir=$(dirname "$f"); suite=$(dirname "$(dirname "$dir")")
  $G -qE '^max_turns:|^timeout_seconds:' "$f" && ev_errs="$ev_errs $f:turns-top-level"
  if $G -qE '^ *criteria:' "$f" && $G -qE '^ *criteria: *[a-zA-Z0-9_./-]+\.md$' "$f"; then
    ev_errs="$ev_errs $f:criteria-is-bare-path"
  fi
  $G -qE '^(grader|extra_checks|skill):' "$f" && ev_errs="$ev_errs $f:legacy-schema"
  for g in $($G -oE 'graders/[a-zA-Z0-9_-]+\.md' "$f" | sort -u); do
    { [ -f "$dir/$g" ] || [ -f "$suite/$g" ]; } || ev_errs="$ev_errs $f:missing-$g"
  done
done
[ -z "$ev_errs" ] && ok "eval case.yaml schema sound" || bad "eval schema errors:$ev_errs"

# Source-dependent cases must load plugin guidance before answering narrated data.
source_eval_errs=$(python3 -B - <<'PY'
from pathlib import Path
import re

for suite in ("output-style", "context-efficiency"):
    for prompt in Path(f"evals/{suite}/cases").glob("*/prompt.md"):
        if not re.search(r"Invoke `dev-flow:[a-z-]+`", prompt.read_text()):
            print(f"{prompt}:no-explicit-source-loading")
        config = prompt.with_name("case.yaml").read_text()
        for tool in ("Read", "Skill"):
            if not re.search(rf"^    - {tool}$", config, re.M):
                print(f"{prompt}:missing-source-tool:{tool}")
for case in ("02-formal-zh", "04-subagent"):
    directory = Path(f"evals/output-style/cases/{case}/graders")
    if "focus: trace" not in (directory / "grader.md").read_text():
        print(f"{case}:artifact-grader-cannot-see-tools-or-file-content")
    if not (directory / "artifact.md").exists():
        print(f"{case}:no-artifact-existence-grader")
opening = Path("evals/output-style/cases/02-formal-zh/graders/decision-first.md")
if not opening.exists():
    print("formal-memo:no-direct-artifact-opening-grader")
elif not all(term in opening.read_text() for term in ("source: file", "path: acceptance-memo.md", "first substantive paragraph", "目的為記錄")):
    print("formal-memo:opening-grader-misses-observed-false-pass")
for skill in Path("skills").glob("*/SKILL.md"):
    text = skill.read_text().split("## Output style", 1)[-1].split("\n## ", 1)[0]
    if "../../references/output-style.md" not in text:
        print(f"{skill}:no-relative-style-source")
wrapper = Path("commands/new-feature.md").read_text()
if "${CLAUDE_PLUGIN_ROOT}/skills/new-feature/SKILL.md" not in wrapper:
    print("new-feature-wrapper:no-explicit-host-root-engine-path")
grader = Path("evals/context-efficiency/cases/02-isolated-brief/graders/output-style.md")
if not grader.exists():
    print("isolated-brief:no-deterministic-style-grader")
else:
    header, pattern = grader.read_text().split("---", 2)[1:]
    if "type: regex" not in header:
        print("isolated-brief:style-grader-is-not-deterministic")
    rules = ["Keep the conclusion first.", "Keep one term per concept.", "Do not add unrelated text."]
    if not re.search(pattern.strip(), " ".join(rules), re.I):
        print("isolated-brief:style-grader-rejects-complete-brief")
    for missing in rules:
        if re.search(pattern.strip(), " ".join(r for r in rules if r != missing), re.I):
            print(f"isolated-brief:style-grader-accepts-missing:{missing}")
PY
)
source_eval_exit=$?
if [ "$source_eval_exit" -ne 0 ]; then
  bad "eval source/grader contract crashed (exit $source_eval_exit):$source_eval_errs"
elif [ -z "$source_eval_errs" ]; then
  ok "source-dependent evals load guidance and reject incomplete briefs"
else
  bad "eval source/grader contract missing:$source_eval_errs"
fi
