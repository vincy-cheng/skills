---
type: llm
focus:
  source: file
  path: acceptance-memo.md
---
# Grade the memo opening only

You are seeing the actual saved memo, not the assistant's final save confirmation.
Apply the existing decision-first requirement without credit for later completeness.

1. Ignore the title, addressee/date/status metadata, separators, and section headings. Quote the first substantive paragraph verbatim.
2. That paragraph must state conditional acceptance AND that pilot entry is allowed only after operations demonstrates restoration from the latest backup. A purpose/background paragraph before this decision fails. A decision or condition in a later paragraph does not repair the opening.
3. Return FAIL if either required opening fact is absent. Return PASS only when both are present in that first substantive paragraph. Evaluate meaning, not one exact Chinese rendering.

Observed negative case — MUST FAIL even if all criteria and evidence appear later:

## 一、開場
本備忘錄提交審查委員會，目的為記錄本次服務驗收的決議、所依據的驗收準則、各項準則對應的佐證，以及決議所附帶的條件。

## 二、決議
決議：有條件接受。於所列附帶條件完成後，得進入受控試行。

A generic purpose opening such as “目的為記錄” delays the decision and is not a decision-first paragraph. Do not accept later decision text because it is somewhere in the file.

First line PASS or FAIL; then quote the first substantive paragraph and give Y/N for decision and backup-restoration-before-pilot condition.
