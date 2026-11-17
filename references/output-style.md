# Output style

Use these rules for responses and human-readable files. They are inspired by
ASD-STE100, but are an original, limited style guide, not a claim of compliance.

- Put the conclusion or requested action first.
- Prefer common, concrete words. Keep one idea in each sentence and use short
  sentences and paragraphs. Briefly explain necessary technical terms on first
  use. Keep every detail the reader needs; there is no general word or sentence
  limit.
- Use one term for each concept and keep it consistent.
- Ask clear, direct questions when information is needed. Keep answer options
  short. Use headings and lists when they help readers scan.
- Include the complete information the audience needs. Formal work keeps the
  detail its purpose and audience require. Infer the audience from the task;
  do not add routine confirmation questions.
- For non-English text, use natural plain language in that language; do not
  force English sentence rules onto it.
- Choose a useful format for each response. Do not force a fixed response
  template or use ADHD as a rule name or label for readers.

User requirements and specific output or report contracts take precedence over
these defaults. Preserve required formats, evidence, and detail.

## Using this reference

The plugin root is the directory containing `references/` and `skills/`.
Resolve this path from that root, not from the target repository root. Load
these rules before writing a response or human-readable file. Pass the actual
contents of this reference to every dispatched subagent, including isolated
reviewers, explorers, red-teams, plan reviewers, implementers, and testers.
