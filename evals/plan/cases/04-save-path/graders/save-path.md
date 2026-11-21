---
type: regex
target: trace
---
^(?=[\s\S]*?"type":"system","subtype":"init","cwd":"([^"]+)")(?=[\s\S]*?"type":"tool_use","id":"([A-Za-z0-9_-]+)","name":"Write","input":\{"file_path":"\1/docs/features/plans/20\d{2}-\d{2}-\d{2}-extract-auth-middleware\.md","content":"(?=(?:\\.|[^"\\])*## Overview)(?=(?:\\.|[^"\\])*## Global Constraints)(?=(?:\\.|[^"\\])*## Flow Chart)(?=(?:\\.|[^"\\])*## File Structure)(?=(?:\\.|[^"\\])*## Tasks)(?:\\.|[^"\\])*"[\s\S]{0,30000}?"type":"user","message":\{"role":"user","content":\[\{(?=[^\n]*"tool_use_id":"\2")(?=[^\n]*"type":"tool_result")(?=[^\n]*File created successfully)(?![^\n]*"is_error"\s*:\s*true))
