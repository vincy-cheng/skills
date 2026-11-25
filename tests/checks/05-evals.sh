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

# Plan case 04 must prove a successful save in the runtime trace, not accept
# narration, a wrong destination, or an unrelated Write result.
plan_write_errs=$(python3 -B - <<'PY'
from pathlib import Path
import json
import re

case = Path("evals/plan/cases/04-save-path")
prompt = (case / "prompt.md").read_text()
grader_path = case / "graders/save-path.md"
expected_literal = "docs/features/plans/YYYY-MM-DD-extract-auth-middleware.md"
if expected_literal in prompt:
    print("prompt-supplies-exact-destination")
if not re.search(r"docs/features/plans/20\d{2}-\d{2}-\d{2}-[a-z-]+\.md", prompt):
    print("prompt-missing-realistic-plan-inventory")
if not grader_path.is_file():
    print("missing-deterministic-save-grader")
else:
    parts = grader_path.read_text().split("---", 2)
    if len(parts) < 3 or not all(term in parts[1] for term in ("type: regex", "target: trace")):
        print("invalid-deterministic-save-grader-header")
    else:
        try:
            pattern = re.compile(parts[2].strip())
        except re.error as error:
            print(f"invalid-save-grader-regex:{error}")
        else:
            cwd = "/fixture/cwd"
            target = f"{cwd}/docs/features/plans/2026-11-22-extract-auth-middleware.md"
            ticks = chr(96) * 3
            good_artifact = f"""# Plan: extract-auth-middleware

## Overview

Extract bearer-token verification into middleware without changing accepted tokens or protected routes.

## Global Constraints

- Preserve the 401 body and keep `/health` public.

## Flow Chart

{ticks}mermaid
flowchart TD
    T1["Task 1: Extract middleware"] --> T2["Task 2: Add tests"]
{ticks}

## File Structure

{ticks}text
src/middleware/authenticateRequest.ts
src/server.ts
{ticks}

## Tasks

- [ ] Extract and wire middleware with focused tests

### Task 1 — Extract and wire middleware

Files: `src/middleware/authenticateRequest.ts`, `src/server.ts`
Verification:
`npm test -- --runInBand` and `npm run lint`
"""
            def trace(path=target, result_id="write-1", error=False, claim_only=False, content=None):
                if claim_only:
                    return f"Saved successfully to {path}"
                init = {"type": "system", "subtype": "init", "cwd": cwd}
                use = {"type": "assistant", "message": {"content": [{"type": "tool_use", "id": "write-1", "name": "Write", "input": {"file_path": path, "content": good_artifact if content is None else content}}]}}
                result = {"tool_use_id": result_id, "type": "tool_result", "content": f"File created successfully at: {path}"}
                if error:
                    result = {"is_error": True, **result}
                return "\n".join(json.dumps(event, separators=(",", ":")) for event in (init, use, {"type": "user", "message": {"role": "user", "content": [result]}}))
            if not pattern.search(trace()):
                print("grader-rejects-successful-write")
            verify_label = good_artifact.replace("Verification:\n", "Verify:\n")
            no_verify_label = good_artifact.replace("Verification:\n", "")
            if any(not pattern.search(trace(content=variant)) for variant in (verify_label, no_verify_label)):
                print("grader-rejects-equivalent-verification-label-or-unlabeled-command")
            negatives = (
                trace(claim_only=True),
                trace(path=f"{cwd}/docs/plans/2026-11-22-extract-auth-middleware.md"),
                trace(path=f"{cwd}/docs/features/plans/2026-11-22-other-feature.md"),
                trace(result_id="unrelated-result"),
                trace(error=True),
                trace(content=""),
                trace(content="Unrelated successful write."),
                trace(content=f"The draft mentions ## Overview, ## Global Constraints, ## Flow Chart, ## File Structure, and ## Tasks, with {ticks}mermaid flowchart TD, - [ ] Extract middleware, ### Task 1, **Files:** src/server.ts, **Verification:** npm test."),
                trace(content="## Overview\n\n## Global Constraints\n\n## Flow Chart\n\n## File Structure\n\n## Tasks"),
                trace(content=good_artifact.replace("flowchart TD\n    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]\n", "")),
                trace(content=good_artifact.replace(f"{ticks}mermaid\nflowchart TD\n    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]\n{ticks}", "flowchart TD\n    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]")),
                trace(content=good_artifact.replace(f"flowchart TD\n    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]\n{ticks}", f"flowchart TD\n{ticks}")),
                trace(content=good_artifact.replace(f"    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]\n{ticks}", "    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]")),
                trace(content=good_artifact.replace("- [ ] Extract and wire middleware with focused tests\n", "")),
            )
            if any(pattern.search(sample) for sample in negatives):
                print("grader-accepts-claim-wrong-path-mismatched-result-or-error")
            empty_chart = good_artifact.replace(f"{ticks}mermaid\nflowchart TD\n    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]\n{ticks}", f"{ticks}mermaid\nflowchart TD\n{ticks}")
            missing_chart_fence = good_artifact.replace(f"{ticks}mermaid\nflowchart TD\n    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]\n{ticks}", "flowchart TD\n    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]")
            unclosed_chart = good_artifact.replace(f"    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]\n{ticks}", "    T1[\"Task 1: Extract middleware\"] --> T2[\"Task 2: Add tests\"]")
            if any(pattern.search(trace(content=bad)) for bad in (empty_chart, missing_chart_fence, unclosed_chart)):
                print("grader-accepts-empty-node-less-or-unclosed-mermaid-chart")
PY
)
plan_write_exit=$?
if [ "$plan_write_exit" -ne 0 ]; then
  bad "plan save-path grader contract crashed (exit $plan_write_exit):$plan_write_errs"
elif [ -z "$plan_write_errs" ]; then
  ok "plan case 04 requires a successful convention-bound Write"
else
  bad "plan save-path grader contract missing:$plan_write_errs"
fi

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

# Architecture source loading must not depend on an LLM believing self-reports.
architecture_grader_errs=$(python3 -B - <<'PYREADS'
from pathlib import Path
for case in ("05-architecture-boundary", "06-architecture-exception", "07-simple-design", "08-architecture-applicability"):
    p = Path("evals/review/cases") / case / "graders/source-reads.md"
    if not p.exists():
        print(f"{case}:missing-deterministic-source-grader")
        continue
    text = p.read_text()
    if not all(term in text for term in ("type: regex", "target: trace", "tool_result", "Architecture checklist", "Clean-code checklist")):
        print(f"{case}:incomplete-source-grader")
        continue
    import json
    pattern = text.split("---", 2)[2].strip()
    import re
    regex = re.compile(pattern, re.M)
    clean = "# Clean-code checklist (review R4)\nshape would actively break under the next change."
    architecture = "# Architecture checklist (review R4)\nA style or pattern preference is not a correctness blocker."
    def result(content, error=False):
        return json.dumps({"type": "tool_result", "content": content, "is_error": error})
    good = result(clean) + "\n" + result(architecture)
    reversed_reads = result(architecture) + "\n" + result(clean)
    invalid = (
        json.dumps({"type": "text", "text": "Read both: " + clean + architecture}),
        result(clean) + "\n" + result(architecture, True),
        result(clean) + "\n" + result("File does not exist: architecture.md", True),
        result(clean) + "\n" + result("# Architecture checklist (review R4)"),
        result(clean),
    )
    if not regex.search(good) or not regex.search(reversed_reads):
        print(f"{case}:rejects-successful-source-reads")
    if any(regex.search(trace) for trace in invalid):
        print(f"{case}:accepts-missing-failed-or-claimed-source-read")
PYREADS
)
architecture_grader_exit=$?
if [ "$architecture_grader_exit" -ne 0 ]; then
  bad "architecture source grader check crashed:$architecture_grader_errs"
elif [ -z "$architecture_grader_errs" ]; then
  ok "architecture evals require deterministic source-read evidence"
else
  bad "architecture source grader contract missing:$architecture_grader_errs"
fi

# Risk-proportionate workflow regression cases must remain complete and source-loaded.
risk_workflow_errs=$(python3 -B - <<'PY'
from pathlib import Path
import re
import json

suite = Path("evals/risk-proportionate-workflow")
expected = {
    "01-document": "execute-tasks",
    "02-bounded-fix": "new-feature",
    "03-small-high-risk": "plan",
    "04-scope-growth": "new-feature",
    "05-context-recovery": "execute-tasks",
    "06-recovery-stop": "execute-tasks",
    "07-legacy-resume": "new-feature",
    "08-expectation-gap": "review",
}
actual = {path.name for path in (suite / "cases").iterdir() if path.is_dir()}
for missing in sorted(set(expected) - actual):
    print(f"missing-case:{missing}")
for extra in sorted(actual - set(expected)):
    print(f"unexpected-case:{extra}")
for name, skill in expected.items():
    case = suite / "cases" / name
    for relative in ("case.yaml", "prompt.md", "graders/grader.md"):
        if not (case / relative).is_file():
            print(f"{name}:missing:{relative}")
    config = case / "case.yaml"
    prompt = case / "prompt.md"
    if config.is_file():
        text = config.read_text()
        for tool in ("Read", "Skill"):
            if not re.search(rf"^    - {tool}$", text, re.M):
                print(f"{name}:missing-source-tool:{tool}")
    if prompt.is_file() and not re.search(rf"Invoke `dev-flow:{skill}`", prompt.read_text()):
        print(f"{name}:missing-source-load:dev-flow:{skill}")
    grader = case / "graders/grader.md"
    if grader.is_file():
        header = grader.read_text().split("---", 2)
        if len(header) < 3 or not re.search(r"^type: llm$", header[1], re.M):
            print(f"{name}:grader-not-discoverable-llm")
        else:
            expected_focus = "last_message" if name in ("01-document", "05-context-recovery", "07-legacy-resume") else "trace"
            if not re.search(rf"^focus: {expected_focus}$", header[1], re.M):
                print(f"{name}:grader-focus-mismatch:{expected_focus}")
    if name == "07-legacy-resume":
        checkpoint = case / "graders/checkpoint.md"
        if not checkpoint.is_file():
            print("07-legacy-resume:missing-checkpoint-grader")
        else:
            parts = checkpoint.read_text().split("---", 2)
            if len(parts) < 3 or not all(re.search(rf"^{field}$", parts[1], re.M) for field in ("type: llm", "focus: last_message")):
                print("07-legacy-resume:checkpoint-grader-header-invalid")
            elif not all(marker in parts[2] for marker in ("A1 leaves", "A2 selects only", "Step 10", "Step 9 evidence gate")):
                print("07-legacy-resume:checkpoint-grader-misses-decision-gates")
case01_prompt = (suite / "cases/01-document/prompt.md").read_text()
case01_grader = (suite / "cases/01-document/graders/grader.md").read_text()
for marker in ("The user has not approved this README edit", "Then answer four separate hypothetical checkpoint records", "assume the README edit was separately approved, completed during build", "previous session wrote Goal status `doc-fix` but was interrupted before the Step 8 evidence decision began", "no verdict or failure was recorded"):
    if marker not in case01_prompt:
        print(f"01-document:missing-authorization-separation:{marker}")
for marker in ("Implementer confirmation is not user approval", "Mentioning the correct confirmation and review gates elsewhere does not cure a violation", "the checkpoint itself must not edit the docs", "resumes Step 8 with incoming `doc-fix` even though interruption happened before a verdict or failure was recorded"):
    if marker not in case01_grader:
        print(f"01-document:missing-behavior-blocker:{marker}")
if not (suite / "README.md").is_file():
    print("missing-suite-readme")

# Cases 01 and 05 grade source reads deterministically from successful tool
# results; the LLM grader scores behavior only.
source_cases = {
    "01-document": [
        "Run the plan's tasks one by one, with TDD.",
        "## Step 8",
        "## Standalone mode (outside dev-flow)",
    ],
    "05-context-recovery": [
        "NEEDS_CONTEXT",
        "# Model routing — role-level lanes for dev-flow subagent dispatch",
    ],
}

def init_event(plugin_root):
    return json.dumps({"type": "system", "subtype": "init", "plugins": [{"name": "dev-flow", "path": plugin_root, "source": "dev-flow@inline"}]}, separators=(",", ":"), ensure_ascii=False)

def read_batch_event(calls):
    content = [{"type": "tool_use", "id": call_id, "name": "Read", "input": {"file_path": path}} for call_id, path in calls]
    return json.dumps({"type": "assistant", "message": {"content": content}}, separators=(",", ":"), ensure_ascii=False)

def result_event(call_id, content, is_error=False, type_first=False, error_first=False):
    item = {"tool_use_id": call_id, "type": "tool_result", "content": content}
    if type_first:
        item = {"type": "tool_result", "tool_use_id": call_id, "content": content}
    if is_error and error_first:
        item = {"is_error": True, **item}
    elif is_error:
        item["is_error"] = True
    return json.dumps({"type": "user", "message": {"role": "user", "content": [item]}}, separators=(",", ":"), ensure_ascii=False)

for name, markers in source_cases.items():
    case = suite / "cases" / name
    source_grader = case / "graders/source-reads.md"
    if not source_grader.is_file():
        print(f"{name}:missing-deterministic-source-grader")
        continue
    raw = source_grader.read_text()
    parts = raw.split("---", 2)
    if len(parts) < 3 or not all(term in parts[1] for term in ("type: regex", "target: trace")):
        print(f"{name}:invalid-deterministic-source-grader-header")
        continue
    try:
        pattern = re.compile(parts[2].strip())
    except re.error as error:
        print(f"{name}:invalid-source-grader-regex:{error}")
        continue
    if any(re.escape(marker).replace(r"\ ", " ").replace(r"\#", "#").replace(r"\-", "-") not in parts[2] for marker in markers):
        print(f"{name}:source-grader-misses-required-marker")
    required_paths = {
        "01-document": [
            "skills/execute-tasks/SKILL.md",
            "skills/new-feature/SKILL.md",
            "skills/doc-fix/SKILL.md",
        ],
        "05-context-recovery": [
            "skills/execute-tasks/SKILL.md",
            "references/model-routing.md",
        ],
    }[name]
    root = "/fixture/plugin"
    def calls(paths=None, result_ids=None, error=False, error_first=False, result_order=None):
        paths = paths or required_paths
        result_ids = result_ids or [f"call-{i}" for i in range(len(markers))]
        events = [init_event(root), read_batch_event([(f"call-{i}", suffix if suffix.startswith("/") else f"{root}/{suffix}") for i, suffix in enumerate(paths)])]
        for i in (result_order or list(range(len(paths)))):
            if i >= len(paths):
                continue
            marker = markers[i]
            events.append(result_event(result_ids[i], marker, is_error=error, type_first=(i % 2 == 1), error_first=error_first))
        return "\n".join(events)
    positive = calls()
    error = calls(error=True, error_first=True)
    wrong_path = calls(paths=["/tmp/unrelated.txt"] * len(markers))
    mismatched = calls(result_ids=[f"wrong-{i}" for i in range(len(markers))])
    claim = "\n".join(f"I read the source and saw {marker}" for marker in markers)
    missing = calls(paths=required_paths[:-1], result_ids=[f"call-{i}" for i in range(len(markers) - 1)])
    if not pattern.search(positive):
        print(f"{name}:grader-rejects-successful-tool-results-or-key-order")
    reordered = calls(result_order=list(reversed(range(len(markers)))))
    split_calls = [init_event(root), read_batch_event([(f"wrong-{i}", f"{root}/tmp/unrelated.txt") for i in range(len(markers))] + [(f"right-{i}", f"{root}/{suffix}") for i, suffix in enumerate(required_paths)])]
    split_calls.extend(result_event(f"wrong-{i}", marker) for i, marker in enumerate(markers))
    split_calls.extend(result_event(f"right-{i}", "unrelated successful source result") for i in range(len(markers)))
    split_call_id = "\n".join(split_calls)
    if not pattern.search(reordered):
        print(f"{name}:grader-rejects-reordered-tool-results")
    if any(pattern.search(trace) for trace in (error, wrong_path, mismatched, claim, missing, split_call_id)):
        print(f"{name}:grader-accepts-error-wrong-path-mismatched-id-claim-missing-source-or-crossed-read")

PY
)
risk_workflow_exit=$?
if [ "$risk_workflow_exit" -ne 0 ]; then
  bad "risk-proportionate workflow case contract crashed:$risk_workflow_errs"
elif [ -z "$risk_workflow_errs" ]; then
  ok "risk-proportionate workflow has eight complete source-loaded cases"
else
  bad "risk-proportionate workflow case contract missing:$risk_workflow_errs"
fi
