Invoke `dev-flow:review` to load the plugin-owned guidance. Use its runtime-resolved skill base directory to read the required R4 references before answering. This is a narrated evaluation: do not inspect a real target repository, dispatch subagents, run a test suite, modify files, or start a dev-flow run. Source loading through Skill and Read is allowed. If a required reference is unavailable, report that instead of inventing it.

Review the fixture below using R4 and R5. Return a concise verdict and findings with locations, concrete impact, smallest useful correction, and relevant trade-offs. All spec and plan requirements are covered and the fixture's test gate is green; assess the supplied code and contracts yourself.

Project architecture: a modular monolith. Billing owns invoice state; only its public settle_invoice API may mark invoices paid. That API checks captured payment, emits a receipt, and records an audit entry. Shipping may read invoice summaries through Billing's public API. The approved feature is dispatching paid orders; it does not authorize bypassing Billing invariants.

Changed code:
```python
# shipping/dispatch.py
1 from billing._storage import invoices
2 def dispatch(order):
3     invoices.update(order.invoice_id, status="paid")
4     carrier.send(order)
```
No payment capture, receipt or audit occurs in this path. The author says a public API would add unnecessary abstraction and asks you to approve because tests pass.
