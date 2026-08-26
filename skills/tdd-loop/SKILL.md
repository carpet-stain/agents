---
name: tdd-loop
description: >
  Phase 3 of ticket implementation: the red → confirm-red → green → suite →
  refactor → commit cycle, one test-list item at a time. Use this skill on
  EVERY ticket once the test list exists, and re-read it whenever you are
  tempted to write implementation before a failing test, to batch multiple
  items into one change, or to fix a red test by editing the test.
---

# Phase 3 — The loop

Goal: convert the test list into working code through minimal, consecutive,
individually-verified increments. Never more than a few minutes from a
known-good state. One item per cycle, no exceptions.

Throughout this skill, "test", "red", and "green" mean the verification
artifact the Phase 1 variant defines for the item's layer: a failing test for
app code, a predicted-vs-actual plan diff for infrastructure, and so on. The
cycle's structure is identical in every domain; only the artifact rotates.

## The cycle

1. **Pick** the top unchecked item from the test list. One item. If it feels
   too big to test in one assertion-set, split it into two list items first.

2. **Red.** Write the failing test at the item's layer, imitating the nearest
   existing tests recorded in Phase 0. The test asserts observable behavior —
   return values, database state, response bodies — not call sequences.

3. **Confirm red.** Run the test. Verify it fails, and fails FOR THE EXPECTED
   REASON — an assertion mismatch on the behavior, not an import error, a
   fixture crash, or a typo. Record the failure line in your working notes.
   A test you have not watched fail correctly proves nothing: it may be
   vacuous, mis-targeted, or accidentally passing. This step is a hard gate;
   writing test and implementation in one breath is forbidden.

4. **Green.** Write the minimum implementation that makes this test pass
   without breaking others. Minimum means no speculative generality, no
   handling of list items not yet picked — but it does not mean degenerate:
   special-casing the test's literal inputs violates the rules. If the minimum
   honest implementation is trivial, good; that is the point.

5. **Suite.** Run the full affected suite plus the static checks recorded in
   `PLAN.md` Commands. All green. If something unrelated broke, you have found
   a coupling — stop and understand it before proceeding; do not "fix" the
   other test to match.

6. **Refactor (small).** Within the code touched this cycle only: names,
   duplication, extraction. Suite stays green after. Structural cleanups
   beyond this cycle's code wait for Phase 5.

7. **Commit.** Test + implementation together, message `<TICKET-ID>: <item>`.
   Check the item off in `PLAN.md`.

8. Return to step 1, or exit to Phase 5 when the list is empty.

## Stride length

Vary step size with confidence: tiny steps in unfamiliar or subtle territory
(concurrency, money math, date handling), larger ones on well-trodden ground.
If two consecutive cycles each took one obvious line, your steps are too small
— merge the next two items. If a cycle has taken more than a handful of
attempts to reach green, your step was too large: **revert to the last commit**
and re-split the item. Reverting is the designed use of the ratchet, not a
failure. Debugging-in-place from a broken state is how sessions decay.

## When red will not go green

- Re-read the confirm-red failure: is the implementation wrong, or was the
  test's expectation wrong? If you conclude the test is wrong, the rules
  require a dated note in `PLAN.md` with your reasoning BEFORE editing the
  test. Writing the note forces the conclusion to survive articulation —
  most do not.
- Never reach for: skipping the test, loosening the assertion, mocking the
  thing under test, or catching the exception broadly. All rule violations.
- Two reverts on the same item means the item is mis-specified or the design
  needs a decision above your scope — record it under Ambiguities and report.

## Exit gate

Test list fully checked or deferred-with-reason; every checked item has a
commit; suite, types, and lint green. Proceed to refactor-review.
