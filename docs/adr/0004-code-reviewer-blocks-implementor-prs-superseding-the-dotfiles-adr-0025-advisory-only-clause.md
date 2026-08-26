# 0004. code-reviewer blocks implementor PRs, superseding the dotfiles ADR-0025 advisory-only clause

Date: 2026-08-26

## Status

Accepted

Supersedes the advisory-only clause of carpet-stain/dotfiles ADR-0025 for the code-reviewer
agent on implementor PRs. The rest of ADR-0025 survives: the deterministic `pr-code-review.yml`
stays advisory on human PRs, and no LLM review is ever a required status check. The dotfiles-side
status annotation on ADR-0025 is a merge-time follow-up in that repo.

## Context

Dotfiles ADR-0025 ruled every LLM reviewer advisory — never gating a merge — on two premises: a
fire-once reviewer whose false positive dead-ends a merge, and a human approval gate already
standing behind it. The code-reviewer audit (agents#57, maintainer-signed charter 2026-08-25)
changed both premises:

- The role is no longer fire-once. The multi-round dance makes a block **appealable**: address →
  decline-with-reasons → escalate to the backlog-manager → human dismisses the review (the
  native, auditable waive). A false positive now costs a round, not a merge.
- agents#55's future auto-merge for implementor PRs _requires_ a gate with teeth standing where
  human review stood. An advisory reviewer cannot be that gate.

What must not regress is outage semantics: ADR-0025's core argument — a required LLM check
hard-blocks every merge on a rate-limit or outage — stays correct.

## Decision

The code-reviewer agent **blocks merges on implementor PRs** via the native review surface: a
standing request-changes review blocks through branch protection's review requirements. Blocking
findings are bounded to four precisely-defined classes (acceptance-criteria violations,
test-gaming, security vulnerability classes, unenforced-convention breaches — the definition in
`agents/code-reviewer.md` is the one home); everything else stays non-blocking feedback.

Fail-open is preserved by construction: the agent is **not a required status check**. Absence of
a review never blocks — only an affirmatively posted request-changes does. A down reviewer
freezes nothing.

The deterministic workflow (`pr-code-review.yml`) keeps ADR-0025's advisory posture unchanged for
human PRs and yields deterministically on implementor PRs (PR author = the implementor identity)
so one reviewer holds the PR thread.

## Alternatives considered

- **Keep the reviewer advisory (status quo)** — rejected: agents#55's auto-merge path has no gate
  then; "advisory" teeth on an unattended pipeline is no gate at all.
- **Required status check instead of request-changes** — rejected, re-affirming ADR-0025's outage
  argument: a required check must _succeed_ to merge, so an outage blocks everything.
  Request-changes semantics give teeth that fail open.
- **Human-only gate (maintainer review on every implementor PR)** — rejected: it's the bottleneck
  the roster exists to remove, and it doesn't scale to the self-driving implementor
  (dotfiles#598).
- **Blocking for the deterministic workflow too** — rejected: the workflow is fire-once with no
  dance, so ADR-0025's false-positive premise still applies to it verbatim.

## Consequences

- Branch protection's review requirements are now load-bearing for implementor PRs; the human
  override is native review dismissal — auditable, per-PR, no config change.
- The dance needs its tripwires wherever the agent runs: round cap (ADR-0042's scheme) then
  escalation to the backlog-manager — enforced by the definition today, by the substrate when
  hosted (dotfiles#576).
- Dismissal rate and declined-blocking rate become the false-positive telemetry
  (dotfiles#545 requirement, recorded in agents#57 D14).
- Revisit if: false-positive blocks are frequent enough that rounds stop being cheap, or the
  specialized-reviewer seam (security/compliance/dba, agents#57 charter) breaks
  one-reviewer-per-PR.
