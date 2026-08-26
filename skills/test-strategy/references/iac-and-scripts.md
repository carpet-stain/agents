# Variant — infrastructure-as-code and operational scripts

Behavior is a desired state; the primary risk is an unintended change to real
systems. The check artifacts differ, but the invariants hold: every check is
observed failing (or diverging) before the change exists, once, at its lowest
catching layer.

## Layer table — IaC (Terraform/OpenTofu, CloudFormation, declarative Pulumi)

| Layer             | Check artifact                                 | What it proves                     |
| ----------------- | ---------------------------------------------- | ---------------------------------- |
| static            | fmt/validate, lint, misconfiguration scan      | syntax, schema, known-bad patterns |
| plan diff         | predicted-vs-actual on the plan output         | nothing unintended is touched      |
| policy evaluation | the repo's policy checks, where they exist     | change stays inside constraints    |
| apply             | CI/human-gated per the repo's workflow         | the real system converges          |
| none              | see "When a test is not required" in the rules | rationale names the catching layer |

- Static checks are whatever the repo's tooling and CI run — discovered in
  Phase 0, never assumed.
- The plan diff is this domain's red→green: write the predicted resource
  actions (add/change/destroy, per resource) in `PLAN.md` **before** running
  plan, then diff the plan output against the prediction. A divergence is red —
  stop and reconcile the prediction or the code before proceeding. A plan run
  without a prior prediction proves nothing.
- Apply is recorded `CI-only`, never run ad hoc from the ticket; done includes
  stating what apply must still verify.

## Layer table — operational scripts

| Layer   | Check artifact                                   | What it proves                           |
| ------- | ------------------------------------------------ | ---------------------------------------- |
| static  | shell lint/format checks the repo runs           | quoting, portability, footguns           |
| harness | the repo's script-test harness, where one exists | behavior against real inputs             |
| dry run | no-op/check mode with a written predicted output | destructive path reviewed before it runs |

A script with no harness and no dry-run mode falls back to the written
prediction discipline: predicted observable effect recorded in `PLAN.md`
before execution, verified after — and the gap flagged in the final report.
