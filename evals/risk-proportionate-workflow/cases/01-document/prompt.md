Invoke `dev-flow:execute-tasks` first. From the plugin runtime base returned or resolved by that Skill invocation, use Read on `skills/execute-tasks/SKILL.md` before answering; do not resolve it from the target repository. For the checkpoint and standalone questions, use separate Read calls on `skills/new-feature/SKILL.md` and `skills/doc-fix/SKILL.md` from the same runtime base. Wait for each Read result before making the next Read call and before answering. This is a narrated evaluation only: do not inspect or modify a real target repository, dispatch workers, or change state.

Scenario: A run is at `execute`. Its approved plan has two small implementation tasks and a README update that documents their new option. The README path and affected paragraphs were identified in planning; there is no scope growth or uncommitted change. The Implementer has confirmed the wording, and the targeted code checks are green. Explain when the README work belongs, how the user-confirmed documentation edit requirement applies, and what independent verification covers afterward.

Then apply the documentation checkpoint to these separate narrated records:
1. Current Test and Review reports match repository, HEAD, base ref and base SHA; the relevant worktree is clean; the complete independent review report records `consistent` with no later drift.
2. The same current matching tuple and clean tree, but the complete independent review report records `drift` in a relevant doc. The proposed repair is within the approved task scope, but no user confirmation has been given.
3. On resume at `doc-fix`, the saved Test report is for a different HEAD than the live repository; the Review report includes the docs judgment but uses the same stale tuple.

For each record, state the checkpoint decision and next permitted action. Is `doc-fix` still independently usable? Do not assume a supplement repairs stale identity or full verification.

Answer the questions only. Distinguish the checkpoint from a mandatory skill dispatch.
