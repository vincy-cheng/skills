---
type: regex
target: trace
---
^(?=[\s\S]*?"plugins":\[\{"name":"dev-flow","path":"([^"]+)")(?=[\s\S]*?"type":"tool_use","id":"([A-Za-z0-9_-]+)","name":"Read","input":\{"file_path":"\1/skills/execute-tasks/SKILL\.md"\}[\s\S]{0,100000}?"type":"user","message":\{"role":"user","content":\[\{(?=[^\n]*"tool_use_id":"\2")(?=[^\n]*"type":"tool_result")(?=[^\n]*NEEDS_CONTEXT)(?![^\n]*"is_error"\s*:\s*true))(?=[\s\S]*?"type":"tool_use","id":"([A-Za-z0-9_-]+)","name":"Read","input":\{"file_path":"(?:\1/references/model-routing\.md|\1/skills/execute-tasks/\.\./\.\./references/model-routing\.md)"\}[\s\S]{0,100000}?"type":"user","message":\{"role":"user","content":\[\{(?=[^\n]*"tool_use_id":"\3")(?=[^\n]*"type":"tool_result")(?=[^\n]*# Model routing — role-level lanes for dev-flow subagent dispatch)(?![^\n]*"is_error"\s*:\s*true))
