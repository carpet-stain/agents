# 3. The enforcement ladder — shift rules left, prose last

Date: 2026-08-26

## Status

Accepted

## Context

The roster audits (agents#53) produced dozens of rules and boundaries needing enforcement, and
the operating model already held the two endpoints — a deterministic gate beats an agent
("Deterministic work stays deterministic"), and a forcing function beats prose — with no ordered
priority between them. Each audit made the placement call ad hoc. The same arc also surfaced the
underlying principle nobody had written: incorporating agents leaves the SDLC intact — the
process doesn't change, the seats do — but gaps a human contributor covered implicitly (judgment
at merge, a glance at CI, "someone would notice") don't get absorbed by an agent the way a human
absorbs them. Every such gap must be surfaced and explicitly covered. The audits' mode-dependent
cells were this principle discovered empirically: role-mode must construct every gate skill-mode
got free from the human session (agents#55).

## Decision

When a rule needs enforcing, implement it at the highest rung it can reach, in order:

1. **Substrate-native** — GitHub rulesets, native review/merge mechanics, required CI checks.
2. **Third-party tooling** — software purpose-built for the check: lefthook, gitleaks, linters.
3. **Own code** — scripts this repo writes and maintains (`scripts/`).
4. **Agent hooks** — PreToolUse and kin triggering scripts at the agent boundary.
5. **Model judgment in a gate** — an agent verdict wired to a substrate enforcement point (the
   blocking code-reviewer's request-changes behind branch protection, the plan gate's labels):
   for rules that need judgment but deserve teeth. Judgment rules are not condemned to prose.
6. **Prose** — a rule in a definition or doc: the last resort, and the only rung that drifts
   silently. Where prevention is out of reach, prose plus a deterministic **detection backstop**
   (an audit skill, a sweep, a drift check) beats bare prose — each rung can fire at prevention
   time or detection time, and prevention beats detection beats hope.

Shift enforcement left into infrastructure; hand it to software built for the job; build our own
only when none exists; write prose only when nothing can execute or check the rule. A rule
sitting on a lower rung than it could reach is a standing defect — where **"could reach" means
worth reaching**: rung choice weighs violation frequency × consequence against build-and-maintain
cost (the D6 inventory-review waive in agents#54 is this valve applied). Every placement also
names its **failure semantics** — fail-open or fail-closed, chosen by whether a false block or a
false pass is the expensive error (required CI fails closed; a down reviewer fails open,
agents#57).

Corollary: **the SDLC is invariant; the gaps get named.** Adding an agent to a seat never changes
the process — it removes the ambient human coverage the seat silently provided, and each uncovered
gap gets an explicit home on a rung (or a named human gate) before the seat is considered filled.

## Alternatives considered

- **Prose-first (write the rule, mechanize later)** — rejected: prose is the rung that drifts
  silently, and "later" reliably never comes; the roster audits found three independently
  hand-rolled copies of one rule (agents#61) — the drift is observed, not hypothetical.
- **Agent-hooks-first (enforce at the agent boundary)** — rejected: hooks bind only the agent
  that runs them, cost tokens, and constrain nothing a human or another tool does; a ruleset or
  CI check binds every actor identically.
- **No ladder (case-by-case judgment)** — rejected: that was the status quo during the audits;
  it works but re-litigates placement every time, which is what a recorded decision exists to end.

Provider-agnosticism note: rung 1 deliberately couples enforcement wiring to the substrate while
the operating model keeps content provider-neutral. No contradiction — enforcement is transport,
not content: the rule stays portable, its wiring is substrate-local and gets rebuilt on a
substrate move.

## Consequences

Designs get measured against the ladder (the design framework's D1/D4 audit questions read
against it); an enforcement idea arrives with its rung named. Building on rungs 1–3 costs more
up front than prose and pays it back in drift immunity. Revisit if a substrate change moves a
rung's ceiling — a new native primitive can obsolete own-code overnight (the code-reviewer's
native review-request did exactly that, agents#57).
