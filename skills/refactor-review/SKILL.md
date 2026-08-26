---
name: refactor-review
description: >-
  Final phase of ticket implementation: a mandatory refactoring pass and self-review diff against
  the ticket. Use this skill on EVERY ticket after the TDD loop completes and before declaring
  done — even when the code feels clean, even when context is long and you want to stop. Being
  tempted to skip this phase is the signal to run it.
---

# Phase 5 — Refactor & self-review

Goal: pay the structural debt the loop deferred, and verify the diff answers
the ticket — the whole ticket and nothing but the ticket. This phase exists
because the loop optimizes locally: each increment was tidy, but the sum can
still be shapeless. It is skipped more reliably than any other phase; that is
why it has its own checklist.

## Part A — Refactor pass

Over the full diff of this ticket (not the whole repo):

1. **Duplication** introduced across cycles — increments often re-derive the
   same helper three times. Extract once, suite green after.
2. **Names** — do they describe the domain behavior, or the order in which you
   discovered things? Rename toward the ticket's vocabulary.
3. **Test-strategy drift** — re-read the Phase 1 table. Did anything planned as
   unit turn out to be mostly glue (its unit tests are all mocks → move the
   coverage to integration and delete the mock theater)? Did an integration
   test turn out to exercise pure logic (→ push down to unit for the edge
   cases, keep one wiring test)? Update the table to match reality.
4. **Coverage-once check** — any behavior now asserted at two layers? Keep the
   lowest, delete the duplicate, note why.
5. Suite + types + lint after every refactor commit. Refactor commits are
   separate from the loop's feature commits and say so in the message.

## Part B — Self-review

Produce the full diff against the base branch and review it as a hostile
reviewer would:

- **Per criterion:** for each AC in `PLAN.md`, point to the exact test(s) and
  code satisfying it. If the pointing finger hesitates, the criterion is only
  technically satisfied — reopen it.
- **Scope creep out:** any change not traceable to an AC or to a Part A
  refactor of ticket-touched code? Revert it, whatever it is.
- **Scope creep in:** any AC whose evident intent is broader than its letter,
  where you satisfied the letter? Flag it in the report rather than silently
  shipping the narrow reading.
- **Hygiene:** debug output, commented-out code, TODOs without ticket refs,
  new dependencies not justified in `PLAN.md`, config or migration files
  touched without an AC requiring it.
- **Comments:** every comment added explains why, matches the recorded prose
  idioms, and none narrates the diff. Comments on untouched code: revert.
- **Docs:** every entry in `## Docs affected` was updated in-kind or carries a
  flag with a reason. Maintained-freedom edits (README, agent-instruction
  files) each pass the provenance test — point to the diff change that
  entailed each one; anything that fails the test is reverted. In
  agent-instruction files, confirm additions are verified repo facts only and
  no instruction, rule, or process line was touched. Any other authored
  documentation without an AC is scope creep; revert it and flag the
  suggestion in the report instead.
- **Deferred items:** every `deferred:` entry still has a reason that survives
  re-reading. Deferred items and flagged ambiguities go in the final report —
  they are the ticket's output too.

## PLAN.md section to produce

```markdown
## Self-review

- AC1 → tests: <paths::names>, code: <paths> — satisfied
- AC2 → ... — satisfied
- Scope check: clean | reverted: <list>
- Unrequested doc edits: none | <file>: <edit> — entailed by <diff change>
- Flags for reviewer: <narrow readings, deferred items, ambiguities, process-change suggestions>
- Refactor commits: <shas/messages>
```

## Exit gate

Definition-of-done checklist from the rules file verified by running the
commands now, self-review section written, flags surfaced in the final report.
Only then say done — and say it with the flags attached, never as a bare
success if flags exist.
