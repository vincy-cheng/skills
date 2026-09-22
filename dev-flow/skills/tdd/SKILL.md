---
name: tdd
description: >-
  Use when implementing any feature or bugfix test-first, before writing implementation code —
  red-green loop, seams, test honesty. Runs standalone in any repo, or as the TDD engine of
  dev-flow step 5 (invoked by execute-tasks per task).
---

# Test-Driven Development

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

Run standalone in any repo, or invoked by `dev-flow:execute-tasks` per task inside a dev-flow run (step 5). Either way the loop is the same.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Exceptions (throwaway prototypes, generated code, configuration) go through your human partner — not around them. **Behavior-preserving refactors arriving from review findings are the one in-loop exception: no new failing test — the existing suite stays green and is the guard.**

## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests verify behavior at seams — public interfaces — never internals, private methods, or side channels.

**Confirm the seam before writing the test:** in dev-flow, the plan's task brief pre-agrees it; standalone, confirm it with your human partner. No test at an unconfirmed seam.

**Before writing any test, name the production change that would make it fail.** If you can't name it, the test doesn't assert anything real.

**Expected values come from an independent source of truth**: a known-good literal, a worked example, the spec. Never recompute the expected value the way the code does — a test that passes by construction can never disagree with the code.

## The loop

**RED — write the failing test.** One behavior, clear name that reads like a specification ("user can checkout with valid cart"), real code — mocks only when unavoidable. Before mocking a dependency, understand its real behavior — a mock of something you haven't read can make the test lie.

**Verify RED.** Run the test. Mandatory, never skip:
- It must **fail** (not error) — for the right reason: the feature is missing, not a typo.
- Errors instead (import typo, missing fixture)? Fix the error, re-run until it fails correctly.
- Passes immediately? You're testing existing behavior or the test is wrong. Fix the test before implementing.

**GREEN — minimal code.** The simplest code that passes the test. Don't add behavior the test doesn't require (YAGNI). Keep it clean as you write: small single-purpose functions, descriptive names, no magic numbers, manage errors where failure is expected.

**Verify GREEN.** Run the test. It passes, no other test broke, output pristine (no errors, warnings). Fails? Fix the code, not the test.

**Next test.** One test → one implementation → repeat. Each test is a tracer bullet responding to what the last cycle taught you.

**Refactor is not a loop phase.** Clean as you write during GREEN; structured refactoring belongs to the review gate — `dev-flow:review` (step 7) inside a dev-flow run. Don't hold behavior changes hostage to cleanup, and don't defer obvious cleanliness to a later pass either. When a behavior-preserving refactor finding comes back from review, apply it without a new failing test — run the existing suite and keep it green; it's the guard.

## Good tests vs bad tests

| Quality | Good | Bad |
|---------|------|-----|
| **Behavioral** | Verifies through the public interface | Tests private methods, mocks internal collaborators |
| **Minimal** | One behavior; "and" in the name? Split it | `test('validates email and domain and whitespace')` |
| **Honest** | Expected value from an independent source | `expect(add(a, b)).toBe(a + b)` — tautology |
| **Refactor-proof** | Survives internal restructuring unchanged | Breaks when you refactor though behavior didn't change |

A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists.

## Anti-patterns

- **Tautological** — the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way), so it passes by construction and can never disagree with the code. The tell: it would pass even if the code were wrong.
- **Implementation-coupled** — mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Horizontal slicing** — writing all tests first, then all implementation. Bulk tests verify *imagined* behavior: you test shapes rather than user-facing behavior, and commit to test structure before understanding the implementation. Work **vertical slices** instead: one test → one implementation → repeat.

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
| "I'll test after" | Tests written after are biased by the code you already wrote — you verify the cases you remembered, and you never watched them fail, so you never proved they can catch the bug. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Already manually tested" | Manual testing is ad-hoc: no record, no re-run when code changes, easy to forget cases under pressure. |
| "Test hard = design unclear" | Listen to the test. Hard to test = hard to use. Simplify the interface. |
| "TDD will slow me down" | TDD catches bugs before commit and lets you refactor without fear. The "pragmatic" shortcut is debugging in production — slower, not faster. |

All of these mean the same thing: delete the code, start over with the loop.

## When stuck

| Problem | Solution |
|---------|----------|
| Test too complicated | The design is too complicated. Simplify the interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract test helpers. Still complex? Simplify the design. |
| Don't know how to test | Write the wished-for API first, then the assertion. Ask your human partner. |

## Bug fixes

Reproduce the bug with a failing test first. Watch it fail, fix the code, watch it pass, keep the test as the regression guard.

**Never fix a bug without a test proving it.** A fix you can't reproduce isn't a fix — it's a hope.

## dev-flow integration

**Standalone mode:** any repo, no state file needed — apply the loop to the task at hand. Before claiming done: every test written first and watched failing; full suite green; output pristine. (In dev-flow, the step 6 test gate runs this check — standalone, you run it yourself.)

**In-flow mode:** `dev-flow:execute-tasks` (step 5) invokes this skill per task, in both its modes — inline runs the loop directly; subagent dispatches implementers who follow it. In-flow rules:

- Commits go through `dev-flow:commit` (Conventional Commits, no AI attribution) — never auto-commit.
- All artifacts stay under `docs/features/` — never `.superpowers/`.
- **No handoff.** This skill never advances, skips, or reorders dev-flow steps. When the loop finishes, control returns to execute-tasks' loop; step order is governed solely by the hard gate in `commands/new-feature.md`.