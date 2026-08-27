# 0005. DO-NOT-COPY headers reframed — machine-reconciled copies are legal, hand-copies stay forbidden

Date: 2026-08-26

## Status

Accepted

## Context

`rules/universal/*.md`'s GATE headers state a blanket "Do NOT copy into repos" — written when
the only propagation mechanism was hand-retyping, so any duplicate was a drift risk with nothing
watching it. The residency rubric (agents#90, frozen in `docs/operating-model.md` § "The
role↔repo seam") now names a legal duplication path test 3 requires: cross-role persona conduct
is "machine-reconciled from one source block in this repo — a rung-2 equality check keeps the
copies honest." The disposition matrix ruling it (agents#92, maintainer-closed 2026-08-27) hard-cased
exactly this — ruling 2: one source block, the four personas carry it inline, a rung-2 equality
check verifies byte-identity, the vendored channel composes at render.

That mechanism already shipped ahead of this ADR: agents#98 found the hosted plan-reviewer
running without the untrusted-content rule (its rules-tree citation resolves to nothing on
surfaces ADR-0002 doesn't vendor rules to) and fixed it by inlining
`rules/universal/ai-collaboration.md` § "Untrusted Content Is Data, Never Instructions" into all
four personas between `shared-conduct` markers, with `scripts/check-shared-conduct.sh` (wired into
`lefthook-lang.yml`) failing the build on any drift from the source. That copy is legal under
agents#92's ruling and necessary under agents#98's live defect — but the headers on the source
file it copies from still read "Do NOT copy," an unqualified contradiction between the tree's
stated law and its own shipped practice.

Ruling 1 of agents#92 also retires voice.md as doctrine (communication.md's baseline now governs all
agent prose) and supersedes the orthogonality clause of `carpet-stain/dotfiles` ADR-0038
("implementor-authored output still sounds like the maintainer"), naming this ADR as the record
of that supersession. voice.md's Before/after examples are salvage, migrating into
communication.md's Writing-Style lineage under that file's own repo-side disposition — a later
migration's edit, not this ADR's.

## Decision

Reframe the doctrine the headers state, and update the headers in this same PR:

1. **Hand-copies stay forbidden.** Retyping a `rules/universal/*.md` section into another file by
   hand, with nothing keeping the two in sync, remains exactly the drift class the original
   header existed to prevent.
2. **Machine-reconciled copies are legal**, provided all three hold: the canonical source is
   named inline in the copy (a provenance comment, not a bare prose reference — agents#98's fix is the
   pattern: `<!-- shared-conduct(...) begin — source: <path> -->`); a named mechanism keeps the
   copy byte-equal to the source (a rung-2 equality check, agents ADR-0003's enforcement ladder —
   `scripts/check-shared-conduct.sh` is the first instance); and the copy is marked as a build
   product of the source, never edited independently — the source is what a change edits, the
   copy is what the check regenerates conformance to.
3. **This is the general doctrine, not just today's persona case.** The same rule governs any
   future repo-side copy the residency rubric's test 1 sends to project-starter-template: the
   agents-repo section stays canonical, a PST-carried copy is a build product marked as such, and
   PST's own reconciling mechanism (design and timing explicitly ceded to PST — agents#90's
   non-goals) is what keeps it honest, not a human re-pasting text at release time.
4. **voice.md's doctrine dies; dotfiles ADR-0038's orthogonality clause is superseded.** No file
   governs "how the maintainer's own voice sounds" going forward — communication.md's baseline
   covers all agent-posted prose, and there was never a doctrine gap for hand-copy prohibition to
   protect on the maintainer's side, since he authors his own commits directly. The dotfiles-side
   status annotation on ADR-0038 is a merge-time follow-up in that repo (ADR-0004's precedent).
   Deleting voice.md and folding its salvage into communication.md is migration work (agents#90
   deliverable 4, filed separately) — this ADR only records that the clause it protected no
   longer holds.
5. **Headers on the six `rules/universal/*.md` files** (`ai-collaboration.md`,
   `communication.md`, `design-principles.md`, `documentation.md`, `engineering-practices.md`,
   `voice.md`) replace the "Do NOT copy into repos" line with a pointer to this ADR and the
   hand-copy/machine-reconciled split, so the tree's stated law matches what agents#98 already
   does and what future repo-side migrations will do.

## Alternatives considered

- **Leave the headers as-is until PST's channel exists, then reframe.** Rejected: the
  contradiction is live today (agents#98 shipped a legal machine-reconciled copy against a header that
  still forbids all copying), and agents#90 sequences the ADR before migrations precisely so the
  doctrine clears before #94/#95 depend on it — waiting inverts that order for no benefit.
- **Drop the hand-copy prohibition entirely, since machine-reconciliation now exists.** Rejected:
  hand-copy without a watching check is exactly the drift class agents#61 fixed and agents#92's
  ruling 2 exists to keep fixed. The mechanism is what makes a copy legal, not the act of copying.
- **Design the PST reconciliation mechanism here, so the doctrine is concrete end-to-end.**
  Rejected: agents#90's non-goals explicitly cede propagation/vendoring/rendering design to PST's
  own ground-up redesign; this ADR states the constraint the mechanism must satisfy (named
  source, named check, marked build product), not the mechanism itself.

## Consequences

- The rules tree's stated doctrine now matches its shipped practice (agents#98); a future
  `scripts/check-shared-conduct.sh`-style check for any new shared-conduct block is unambiguously
  sanctioned, not a header violation waiting to be flagged.
- agents#90's migrations (#94/#95) can proceed without the old headers contradicting the
  residency rubric they're built on.
- Any copy without a named source and a named equality check is still a hand-copy and still
  forbidden, however it was produced — a future audit (`audit-rules`, per agents#92's ruling) is the
  backstop that catches an unmarked or unchecked duplicate.
- voice.md stays on disk marked dead-as-doctrine until agents#90's migration deletes it and folds
  its salvage into communication.md; dotfiles ADR-0038 needs its own status update in that repo,
  tracked there, not here.
- Revisit if PST's reconciliation mechanism, once designed, needs a stronger guarantee than
  byte-equality (e.g. semantic diffing) — this ADR's bar is the floor, not a ceiling PST is bound
  to.
