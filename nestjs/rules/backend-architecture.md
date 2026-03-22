---
paths:
  - "src/**/*.ts"
  - "test/**/*.ts"
  - "*.module.ts"
  - "*.controller.ts"
  - "*.service.ts"
---
# Backend Architecture — Quick Reference

> **Full reference**: Use the `hexagonal-architecture` skill for detailed patterns, code examples, and directory structures.

## Core Principles

| Principle | Rule |
|-----------|------|
| **Dependency Inversion** | Domain never depends on infrastructure. Always depend on interfaces |
| **Pure Domain** | Entities and Domain Services are framework-independent |
| **Single Responsibility** | One Use Case = one feature |
| **Immutable Entities** | Private constructor + factory methods (create/reconstitute) |

## Layer Rules

```
Presentation → Application → Domain ← Infrastructure
                    ↓            ↑
              (uses)      (implements)
```

- **Domain**: Entities, Value Objects, Repository Interfaces (Ports), Domain Errors — NO framework imports
- **Application**: Use Cases, orchestration, @Transactional — depends only on Domain
- **Infrastructure**: Repository Impl (Drizzle), Mappers, External Adapters — implements Domain Ports
- **Presentation**: Controllers, DTOs, Guards — entry point only

## Mandatory Patterns

1. **Entity**: Private constructor, `create()` for new, `reconstitute()` from DB
2. **Repository**: Interface in Domain with Symbol token, implementation in Infrastructure
3. **Mapper**: `toDomain()` / `toPersistence()` — never expose DB schema to Domain
4. **Use Case**: Single `exec()` method, @Transactional, clear Input/Output types
5. **DI Registration**: `{ provide: SYMBOL_TOKEN, useClass: ImplClass }`

## Anti-Patterns to Avoid

- **Anemic Domain**: Business logic must live inside Entity, not in Service
- **God Use Case**: Split multi-responsibility Use Cases into separate classes
- **Leaky Abstraction**: Domain must never reference Drizzle, DB tables, or framework decorators
- **Circular Dependencies**: Use Domain Events for cross-module communication

## Scale Decision

| Scale | Trigger | Key Addition |
|-------|---------|-------------|
| Small → Medium | 3+ domains, 3+ developers | Module separation, Repository Interfaces |
| Medium → Large | 10+ domains, MSA planned | Bounded Contexts, Aggregates, CQRS, Domain Events |
