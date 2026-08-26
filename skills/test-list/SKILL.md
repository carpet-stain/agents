---
name: test-list
description: >
  Phase 2 of ticket implementation: enumerate every behavior and edge case as a
  checklist before entering the TDD loop. Use this skill on EVERY ticket right
  after test-strategy and before writing any test or implementation code. Also
  return to this skill mid-loop every time you notice a new case, question, or
  concern — it gets APPENDED here, never chased immediately.
---

# Phase 2 — Test list

Goal: dump the whole problem out of your head into `PLAN.md`, so the loop can
consume it one item at a time. The list is a priority queue for attention: you
hold exactly one item in focus, and the list holds the written promise to
handle the rest. This is the mechanism that prevents both overwhelm and the
signature failure of noticing an edge case in passing and silently dropping it.

## Steps

1. For each row of the test-strategy table, enumerate the concrete cases:
   happy path, boundaries (empty, zero, one, max, off-by-one), invalid inputs,
   error paths, idempotency/ordering where relevant, and any case the ticket
   text or code reading surfaced.
2. Phrase each item as a checkable behavior with its layer tag, specific enough
   that the failing test writes itself:
   - GOOD: `[ ] (unit) order size rounds half-even to 2dp — 0.005 → 0.00`
   - BAD: `[ ] handle rounding`
3. Order the list: start with the simplest happy-path item that forces the
   interface into existence (the classic first move), then boundaries, then
   error paths. Prefer an order where each item builds on the last.
4. Mark items you judge out of scope with `deferred:` and a one-line reason.
   Deferred is a visible decision, not a deletion.

## During the loop (standing rule)

When a new case occurs to you mid-implementation: append it here with a layer
tag, then return to the item in progress. Do not chase it. Do not handle it "as
long as I'm in the file." The only exception is when the new case proves the
current increment's design wrong — then finish or revert the current increment
first, and pick the new item next.

## PLAN.md section to produce

```markdown
## Test list

- [ ] (unit) AC1: ...
- [ ] (unit) AC1: ...
- [ ] (integration) AC1: ...
- [ ] (contract) AC2: ...
- deferred: (e2e) full pipeline smoke — covered by existing nightly, reason: ...

## Discovered during loop

- [ ] (unit) ... <!-- appended items land here with a date -->
```

## Exit gate

Every test-strategy behavior appears as at least one concrete item; every item
names inputs/expectations specifically enough to write the failing test without
further thought; ordering chosen. Then proceed to the tdd-loop skill.
