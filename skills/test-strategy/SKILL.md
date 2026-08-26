---
name: test-strategy
description: >-
  Phase 1 of ticket implementation: map every acceptance criterion to a verification layer with
  written rationale. Use this skill immediately after Phase 0 (orient) on EVERY ticket, before
  writing the test list and before any test or implementation code. Also re-consult it mid-ticket
  whenever a behavior turns out to live at a different boundary than planned. Select the domain
  variant from references/ based on what the repo is.
---

# Phase 1 — Verification strategy

Goal: decide, per behavior, the cheapest check that would fail if that behavior
broke. The location of the risk determines the layer. Output is the
`## Verification strategy` section of `PLAN.md`.

## The master rule (domain-independent)

For each acceptance criterion ask: **what is the failure I am defending
against, and where does it live?** Then pick the lowest layer at which that
failure is observable. A "check" is whatever verification artifact the domain
uses — a test, a predicted-vs-actual diff, a policy evaluation. The invariants
apply to all of them: every check must be observed failing before the change
that satisfies it exists, and each behavior is verified once, at its lowest
catching layer.

## Select the domain variant

Based on Phase 0's boundary inventory and the nature of the repo, read exactly
one variant file and use its layer table:

- `references/app-service.md` — application code: services, APIs, libraries,
  CLIs, jobs. Anything whose behavior is functions transforming inputs to
  outputs across databases, queues, and HTTP surfaces.
- `references/iac-and-scripts.md` — infrastructure-as-code (Terraform/OpenTofu,
  CloudFormation, Pulumi in declarative style) and operational shell scripts.
  Anything whose "behavior" is a desired state and whose primary risk is an
  unintended change to real systems.
- `references/config-and-dotfiles.md` — repos that are predominantly
  configuration consumed by other tools: dotfiles, YAML/TOML/JSON config
  trees, editor/shell setups. Anything where a verification harness may not
  exist and "red" may need its degraded written-prediction form.

Mixed repos: classify per touched surface, not per repo — a ticket touching a
service and its Terraform module uses both variants, each for its own files.
If neither variant fits (data pipelines, ML evals, mobile), apply the master
rule from first principles, write the improvised layer table into PLAN.md, and
flag in the final report that the pack lacks a variant for this domain.

## Rules of the mapping (all domains)

- Every AC gets at least one layer. An AC may decompose into behaviors at
  different layers. Decompose explicitly.
- Each behavior is checked once, at its lowest catching layer. Planning the
  same behavior at two layers requires a written justification, or delete one.
- `None` is a legitimate layer with a mandatory rationale — see "When a test is
  not required" in the rules file. The rationale names where the failure would
  be caught, never why checking is inconvenient.
- If the repo's idioms (from Phase 0) contradict the variant's table, follow
  the repo and note the deviation. Consistency beats purity inside someone
  else's codebase.

## PLAN.md section to produce

```markdown
## Verification strategy

Variant: <app-service | iac-and-scripts | improvised: ...>

| AC  | Behavior | Layer | Rationale (failure defended against) |
| --- | -------- | ----- | ------------------------------------ |
| AC1 | ...      | ...   | ...                                  |
```

The rationale column is mandatory and must name the failure, not restate the
layer ("integration because it's the database" is not a rationale; "the join
could silently drop rows" is).

## Exit gate

Variant selected and recorded; every AC appears in the table; every behavior
has a failure-naming rationale (including every `none` row); no behavior
appears at two layers without written justification. Then proceed to the
test-list phase (the rules pack's Phase 2 gate — no dedicated skill).
