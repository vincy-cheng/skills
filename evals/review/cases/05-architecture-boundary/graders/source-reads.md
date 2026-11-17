---
type: regex
target: trace
flags: m
---
(?:(?=[^\n]*"type"\s*:\s*"tool_result")(?=[^\n]*# Clean-code checklist \(review R4\))(?=[^\n]*shape would actively break under the next change\.)(?![^\n]*"is_error"\s*:\s*true)[^\n]*\n[\s\S]*?(?=[^\n]*"type"\s*:\s*"tool_result")(?=[^\n]*# Architecture checklist \(review R4\))(?=[^\n]*A style or pattern preference is not a correctness blocker\.)(?![^\n]*"is_error"\s*:\s*true)[^\n]*|(?=[^\n]*"type"\s*:\s*"tool_result")(?=[^\n]*# Architecture checklist \(review R4\))(?=[^\n]*A style or pattern preference is not a correctness blocker\.)(?![^\n]*"is_error"\s*:\s*true)[^\n]*\n[\s\S]*?(?=[^\n]*"type"\s*:\s*"tool_result")(?=[^\n]*# Clean-code checklist \(review R4\))(?=[^\n]*shape would actively break under the next change\.)(?![^\n]*"is_error"\s*:\s*true)[^\n]*)
