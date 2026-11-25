# Architecture checklist (review R4)

Read this and `clean-code.md` before R4. Architecture principles help identify concrete problems; following a pattern is not a goal.

## Establish applicability

Use project documentation and code to establish the intended architecture. If they disagree or intent is unclear, flag a question instead of assuming a pattern.
Start with changed code and affected boundaries. Expand only when a connected risk justifies it; this is not a whole-project architecture audit.
Do not infer required MVC, modular monoliths, classes, or interfaces from directory names or personal preference.

## Boundary checks

- **Responsibility** — unrelated reasons to change mixed together; business rules duplicated across entry points.
- **Dependency direction** — a dependency crosses the project's intended layers or couples stable policy to volatile details.
- **Cycles** — circular dependencies make initialization, changes, tests, or independent module use unsafe.
- **Encapsulation** — consumers access internal state, storage, or implementation details instead of an established public boundary.

## SOLID — where the changed code makes it relevant

| Principle | Check | Applicability and limits |
|-----------|-------|--------------------------|
| Single responsibility (SRP) | Do distinct reasons to change force unrelated behavior into the same unit? | Assess actual responsibilities and change patterns, not function length or class count alone. |
| Open/closed (OCP) | Does a required extension repeatedly modify stable policy or duplicate dispatch logic? | Use current requirements or demonstrated extension pressure; do not add abstractions for hypothetical extensions. |
| Liskov substitution (LSP) | Can an implementation replace another without breaking callers' behavior contracts, including errors and pre/postconditions? | Applies to actual substitution contracts, including protocols and callbacks, not only class inheritance. |
| Interface segregation (ISP) | Must consumers depend on capabilities they do not use, causing concrete change or implementation costs? | Applies to shared contracts; a broad interface alone does not justify splitting it without affected consumers. |
| Dependency inversion (DIP) | Do details control policy and create concrete change or testing costs across the intended boundary? | Direct dependencies can be sufficient; do not require an interface or DI container without a useful boundary. |

## Conditional architecture checks

- **MVC — only when the project adopts it.** Check that controllers coordinate input/output, views present data, and domain rules follow the project's model boundary. Respect documented variants; do not impose MVC on other architectures.
- **Modular monolith — only when the project adopts it.** Check module public APIs, ownership of data and internals, and cross-module cycles. Internal table writes or imports can bypass invariants; examine actual contracts and consequences. Do not prescribe microservices or extra runtime hops as a default correction.

## Findings and trade-offs

Pattern deviation alone cannot justify a finding or block approval. Simple designs and justified exceptions can pass without extra layers, interfaces, or classes.
For each structural recommendation, state the file:line, concrete problem, practical impact, and smallest useful correction.
Explain the concrete benefit and relevant costs: implementation effort, added maintenance complexity, and runtime overhead. Use qualitative costs when numbers are unknown; do not invent estimates.
Prefer the existing useful boundary or a local correction over speculative flexibility. Preserve justified exceptions and the project's constraints.
Performance claims require evidence, such as measurements or a demonstrated execution path and operation count. Unverified performance concerns remain questions, not established findings.
Use R5's existing severity and follow-up contract. A style or pattern preference is not a correctness blocker.
