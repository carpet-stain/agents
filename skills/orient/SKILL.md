---
name: orient
description: >-
  Phase 0 of ticket implementation: reconnaissance before touching any code. Use this skill at
  the very start of EVERY ticket, before reading any skill about tests or writing any code,
  whenever you are asked to implement, fix, or change anything described by a ticket. If you are
  about to edit code and no PLAN.md exists for this ticket, stop and run this skill first.
---

# Phase 0 — Orient

Goal: understand the ticket and the territory before forming any opinion about
the solution. Output is the first half of `PLAN.md`. No implementation code, no
test code, no design decisions yet.

`PLAN.md` is a branch-resident working file: it is deleted before the finalize
squash and never merges. Its restated criteria are an execution working copy —
the ticket's top post stays the authoritative spec (one home).

## Steps

1. **Restate the acceptance criteria.** Rewrite each criterion from the ticket
   as a concrete, checkable behavior: given X, when Y, then Z. If a criterion
   cannot be restated this way (vague, unmeasurable, contradictory), record it
   under `## Ambiguities` and stop per the rules — report rather than guess.
   Number the criteria (AC1, AC2, ...); later phases reference these IDs.

2. **Locate the relevant code.** Search the codebase for the modules, functions,
   routes, tables, and jobs the ticket touches. List each path with one line on
   its role. Follow the call chain one level out in each direction — the caller
   above and the dependency below — so you know the blast radius of a change.

3. **Read the nearest existing tests.** Find the three tests closest to the code
   you will touch. Read them fully. Record, in `PLAN.md`:
   - the test framework and runner invocation (exact command)
   - how the database/infrastructure is stood up (fixtures, containers, factories)
   - how HTTP and third-party calls are faked, if at all
   - naming and file-placement conventions

   You will imitate these idioms. Do not import patterns from your training data
   when the repo already has an idiom, even if you think yours is better.

4. **Record prose idioms.** From the nearest files you will touch: comment
   density and register (terse vs. explanatory), doc-comment/docstring
   convention and where it applies (public API only vs. everywhere), and any
   documentation style the repo enforces. Same imitation rule as tests.

5. **Discover entailed documentation.** Search the repo's docs (readmes,
   docs directories, config references, changelog) for mentions of the
   surfaces this ticket touches — module names, commands, flags, config keys,
   endpoints. Record the hits as a `## Docs affected` list in `PLAN.md`. These
   are update obligations per the rules; Phase 5 checks each one.

6. **Inventory the boundaries.** For the code you will touch, classify each
   surface it crosses:
   - pure logic (no I/O)
   - own database (real SQL you control)
   - own HTTP/API surface (routes, serialization, middleware)
   - internal service or queue you control
   - third-party API you do not control

   This inventory feeds Phase 1 directly.

7. **Record how to run things.** Exact commands for: full test suite, single
   test file, and every static check. Discover checks from two sources: the
   repo's local tooling AND its CI configuration — read the CI pipeline
   definitions and list every check CI runs on a pull request, with the local
   equivalent command for each. CI is the authority on what checks exist; a
   check with no local equivalent is recorded as `CI-only`. If a check exists
   in neither, record `none` — the definition-of-done gates bind to this list,
   so absence must be a discovered fact, not an assumption. Run each local
   command once now to confirm it works and to capture the pre-existing
   baseline (note any tests already failing on main — they are not yours to
   fix and not yours to break further).

## PLAN.md template (first half)

```markdown
# <TICKET-ID>: <title>

## Acceptance criteria (restated)

- AC1: Given ... when ... then ...
- AC2: ...

## Ambiguities

- (none | list — if non-empty, STOP and report)

## Touched code

- path/to/module.py — role
- ...

## Testing idioms observed

- Runner: `<command>`
- Infra: <how tests get a database, etc.>
- Fakes: <network-boundary mocking style>
- Conventions: <naming, placement>
- Nearest tests imitated: <three paths>

## Prose idioms observed

- Comments: <density, register>
- Doc-comments: <convention, where applied>

## Docs affected

- <doc path> — mentions <touched surface> (update obligation)
- (none)

## Boundary inventory

- <surface> → <classification>

## Commands

- Suite: `...` Single: `...` Types: `...` Lint: `...`
- Baseline: <clean | pre-existing failures listed>
```

## Exit gate

`PLAN.md` exists with every section filled, ambiguities empty (or reported and
resolved), and baseline commands actually executed. Then proceed to the
test-strategy skill.
