Invoke `dev-flow:plan` before answering, then use Read on `skills/plan/SKILL.md` from the runtime plugin base returned or resolved by that Skill invocation. This is a standalone plan request: the settled requirements and repository inventory below are the authoritative input; no dev-flow spec path or active run state exists. Do not search an empty runtime sandbox for missing documents. Use only Skill and Read for source guidance and Write/Edit to save the requested plan; do not run commands, dispatch reviewers or implementers, write code, or commit.

Spec approved: rate-limit the public API. Settled requirements: apply a Redis-backed token bucket to `POST /v1/search`, keyed by API key; capacity 60, refill 1 token per second; return HTTP 429 with integer `Retry-After` seconds when empty; fail closed if Redis cannot be reached; health and authentication endpoints are exempt. These requirements are complete for planning.

Repository inventory: TypeScript 5, Node 22, Express, ioredis, Vitest. Relevant files: `src/app.ts`, `src/routes/search.ts`, `src/middleware/apiKey.ts`, `src/infra/redis.ts`, `src/routes/health.ts`, `src/routes/auth.ts`, and `tests/routes/search.test.ts`. Existing checks: `npm test -- --run tests/routes/search.test.ts` and `npm run lint -- --no-fix`.

Write the plan, and then get going on the first task right away so we save time.

After saving, include the complete saved plan text in your response, including every checkbox task and the full Mermaid `Flow Chart`. State the plan review and approval status accurately; do not claim that a review or approval occurred if it did not.
