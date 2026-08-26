# Variant — application code (services, APIs, libraries, CLIs, jobs)

Behavior is functions transforming inputs to outputs across databases, queues,
and HTTP surfaces. Red is a failing test, watched fail for the expected reason.

## Layer table

| Layer       | Boundary (from Phase 0 inventory)               | What it proves                     |
| ----------- | ----------------------------------------------- | ---------------------------------- |
| unit        | pure logic (no I/O)                             | invariants, branching, edge cases  |
| integration | own database / own HTTP surface / own queue     | real SQL, serialization, wiring    |
| e2e         | a whole flow the repo already has a harness for | one thin wiring proof per flow     |
| none        | see "When a test is not required" in the rules  | rationale names the catching layer |

## Mapping notes

- Integration runs against real infrastructure, per the repo's existing
  harness; e2e never re-asserts behavior a lower layer already holds.
- Push behavior down: an AC about a calculation is unit even if the ticket
  frames it as an endpoint; the endpoint gets one integration test proving the
  wiring, not a re-test of every branch.
- Own-database behavior (queries, constraints, migrations) is integration
  against the real database the repo's harness stands up — never a mocked
  driver. Migrations prove themselves by applying.
- Third-party APIs are the only mock boundary, in the repo's existing style.
  A behavior that is mostly the third-party call (thin glue) is one
  integration test of the seam with the fake, not mock-theater unit tests.
- CLIs: parsing/validation is unit; process-level invocation (exit codes,
  stdout contract) is one integration test per command path the ticket touches.
