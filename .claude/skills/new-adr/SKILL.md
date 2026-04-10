---
name: new-adr
description: Scaffold a new Architecture Decision Record, auto-numbered from existing ADRs
argument-hint: [decision-name e.g. use-event-driven-curing]
---

# New Architecture Decision Record

Create a new ADR at `docs/adrs/` for: `$ARGUMENTS`

## Steps

1. **List existing ADRs** — `ls docs/adrs/` to find the next number (NNN format, starting at 001).

2. **Gather context** — Run `git log --oneline -10` and read last CHANGELOG section for background.

3. **Create the ADR** at `docs/adrs/NNN-$ARGUMENTS.md`:

```markdown
# ADR-NNN: [Title]

**Status:** Proposed
**Date:** [today's date]
**Author:** [git user]

## Context

[What prompted this decision? What problem are we solving?]

## Decision

[What did we decide?]

## Consequences

### Positive
- [benefit]

### Negative
- [trade-off]

## Alternatives Considered

### [Alternative 1]
- **Pros:** ...
- **Cons:** ...
- **Why rejected:** ...

## References

- [Related commits, issues, docs]
```

4. **Update CHANGELOG** — Note the new ADR.

## Important

- Pre-fill Context from recent git history and CHANGELOG
- Use kebab-case for the filename
- ADRs are append-only — never modify status of existing ADRs without explicit request