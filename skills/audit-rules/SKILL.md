---
name: audit-rules
description: >-
  Audits the global Claude Code agent-config rules tree (~/.claude/rules) for
  contradictions and topic/length sprawl, checks AGENTS.md/README.md/docs for content
  substantially duplicated across them, and checks agent definitions for encoded repo
  facts a role should discover at runtime, reporting proposed fixes without editing
  anything. Use when asked to audit, review, or check the rules tree for contradictions,
  conflicting directives, files that have grown too long or cover more than one topic,
  repo docs that restate the same content in more than one place, or agent definitions
  that hardcode a repo's conventions. Read-only — never invoke this to apply a fix, only
  to find issues.
argument-hint: "[path]"
allowed-tools: Read, Glob, Grep
disallowed-tools: Write, Edit
---

# Audit Rules

Read-only audit of the global agent-config rules tree for the two maintenance issues the
removal test cares about: contradictions and sprawl. Also checks this repo's own docs
(AGENTS.md/README.md/docs) for content replicated across them — a doc↔doc instance of the same
single-source-of-truth problem, and a named cause of sprawl — and agent definitions for
encoded repo facts (the role↔repo seam's drift detector). Report findings and proposed
fixes — never edit anything yourself. `disallowed-tools` already blocks Write/Edit
structurally; treat that as a guarantee, not just a reminder.

## Scope

Read target: `~/.claude/rules/**/*.md`, plus the agent definitions where they're found —
`~/.claude/agents/**/*.md` when deployed, and the current repo's `agents/*.md` when present
(read each definition once; if both locations resolve to the same content, one read suffices).
Never hardcode a specific repo's path (e.g. a dotfiles checkout) — this must work from any repo
where the rules are deployed.

If invoked with a path argument, scope the audit to that file or directory instead of the whole
tree (useful mid-edit on a single file). Otherwise audit everything.

Always read the current repo's own `AGENTS.md` and `README.md` when they exist, plus any
top-level `docs/*.md` (not nested subdirectories — see Cross-doc replication check's scope note).
These aren't optional context: the local-doc contradiction check below, the AGENTS.md length
check under Sprawl, and the Cross-doc replication check all depend on them, and none may silently
skip `README.md` when it's present. If the repo uses a _real_ `CLAUDE.md` (not a symlink to `AGENTS.md`)
as its canonical agent doc, read that too and treat it as the subject wherever these checks say
`AGENTS.md` — a `CLAUDE.md` symlink resolves to `AGENTS.md`, so read it once, not twice.

## Contradiction check

Read every file in scope fully, then look for:

- **Within-file**: a file asserting X in one section and not-X in another — e.g. a file that
  argues a cost is negligible in one section, then treats the same cost as significant elsewhere.
- **Cross-file**: two rules files disagreeing — e.g. a `universal/` file and a `tools/` file
  recommending opposite defaults.
- **Local-doc drift**: the repo's own `AGENTS.md` (or a real `CLAUDE.md`) / `docs/` disagreeing
  with a rules file. Under LOCAL-WINS a contradiction is _allowed_ — the repo wins — so the target
  is _accidental drift_, not deliberate override, and the signal is a marker, not tone. A section
  carrying `> Overrides **<rule>.md** § … — reason: …` (the marker `compose-agents` writes when a
  human confirms an override) is a settled departure: skip it. Flag an _unmarked_ contradiction,
  and propose the resolution — either adopt the rule's semantics, or record the override by adding
  that marker so it stops reading as accidental and both this check and `compose-agents` stop
  re-flagging it.

Report most-confident first. Each finding quotes both locations (file path + the specific
sentence) and states plainly why they conflict.

## Sprawl check

**Rules tree** (`rules/**`) gets two independent signals:

- **Length**: files over ~200 lines — the threshold `README.md`'s own "Why the rule
  files are terse" section names. The Read tool's line-numbered output gives you the count for
  free; no need to shell out.
- **Topic span**: does the file cover more than one coherent topic? This is a qualitative
  judgment from reading the content, not a heading-count metric — the precedent is
  `philosophy.md` splitting into the four `universal/` files once it outgrew a single topic.

**AGENTS.md and `docs/*.md`** get a length-only check, against the separate, higher threshold
`README.md`'s "Why the rule files are terse" section names for composed per-repo guides
(soft-warn / firm-flag). Don't flag topic span there — spanning many topics is AGENTS.md's job.
When a file crosses the threshold, don't just report "too long": check it against the
Restated-enforcement check below and for unpruned topic overlap between its own sections, and
point at whichever applies as the cause and the pointer-form/de-dup prune as the remedy.

### Sprawl reduction playbook (AGENTS.md over threshold)

"Too long" alone re-derives the same menu every run. Once a cause above applies, propose cuts
in this order, highest-confidence first:

1. **Signpost + link.** A section re-explaining content another doc owns collapses to a 1-3
   line essence plus a pointer (`see README.md § ...`, or this repo's doc-home-map if one
   exists). Verify the target doc actually covers it before cutting toward it — pointing at a
   doc that doesn't hold the material loses the content, it doesn't relocate it.
2. **Drop restated-enforcement.** Prose spelling out an exact value a config already enforces
   (a CI regex's allowed-type list, a linter's rule codes) is the Restated-enforcement check's
   target — cut it there, not just here. Applied across a whole rules tree, this is usually the
   largest single trim available, since enumerable specs tend to accrete in prose over time.
3. **Cut restated-principle sections.** A repo-local section that just re-lists an
   always-loaded `rules/universal/*` principle is pure duplication — the universal rule applies
   every session regardless of whether AGENTS.md repeats it. Keep only the repo-specific slice
   (e.g. which doc owns which fact); drop the generic restatement.
4. **Collapse intra-file overlap.** Two sections echoing the same point (a checklist repeated
   in two places, a rule stated once under "editing" and again under "git workflow") merge into
   one, cross-referenced from where the other used to be.
5. **Titles over prose.** For an enumerated list, keep the scannable numbered heading plus one
   pointer to the doc that owns the reasoning; cut the per-item explanatory paragraph.
6. **Merge duplicate command blocks.** Near-identical fenced command examples collapse to one.
7. **Fix source-of-truth direction.** If AGENTS.md holds mechanics another doc should own, move
   the mechanics there and have AGENTS.md point — don't just trim in place. Watch for the
   circular-pointer trap: the two docs must not each say "see the other."

**The honest floor.** After exhausting 1-7, the remainder is legitimate unique agent content
(layer map, source-of-truth map, failure-stage semantics) already at essence-plus-pointer —
don't force it thinner by externalizing high-value content behind an extra hop just to clear
the firm-flag. Report "restatement and overlap eliminated; residual N lines are unique
content," not "still over threshold, keep cutting."

## Restated-enforcement check

AGENTS.md (or a rules file) should point at a config that already enforces something, not
restate the config's exact detail as prose — the same signpost-vs-spec distinction
`compose-agents` now applies when instantiating (see its "Pointer-form for enforced specs"
step). Flag prose in scope that enumerates an exact, mechanically-checkable value — a literal
list of allowed values, a regex, a numeric threshold — that a config file present in the current
repo already defines byte-for-byte. A Conventional-Commit type list restated in prose when a CI
workflow's regex already enforces it is the shape to look for; a lint-rule-code list restated
when a linter config already lists them is the same shape.

Don't flag workflow _shape_ (step ordering, when to squash, when to open a PR) even when a slow
or CI-only gate enforces it — that's guidance no config can teach ahead of time, not a duplicated
spec, and removing it would just push discovery to the most expensive point. Only the enumerable
detail itself is the target.

Each finding quotes the restating prose and the enforcing config, and proposes the pointer-form
rewrite — same format as the Contradictions check, this is not a new report shape.

## Cross-doc replication check

carpet-stain/dotfiles#140's restated-enforcement check is doc↔config: prose restating a spec a
config already enforces. This check is the doc↔doc sibling — same single-source-of-truth
violation, different pair: substantial content restated across AGENTS.md, README.md, and
top-level `docs/*.md` instead of living in exactly one and being pointed at from the others.
Unpruned replication between these is a named top cause of AGENTS.md's length problem
(carpet-stain/dotfiles#178) — this check names
which content to cut, length only measures the symptom.

**Substantial** means a full sentence, list item, or table row making the same claim with the
same specifics (not just both docs mentioning "XDG" or "Homebrew") — near-verbatim wording isn't
required, same claim/same specifics is what makes it substantial. A shared proper noun, tool
name, or one-line cross-reference is not substantial; don't flag those. If in doubt whether a
match clears the bar, don't report it — this check should stay quiet on noise, not cry wolf on
every shared word.

For each substantial match:

- Quote both locations (file + the specific passage) side by side.
- Propose which doc should own it and which should point instead of restate. Use this repo's own
  ownership split if a "one home per fact" doc-home-map exists (check for it — AGENTS.md may
  define one); absent that, default to the shape both README.md and AGENTS.md already state for
  themselves in this repo: README is the front door (what this is, why, install, use), AGENTS.md
  is how to work here. Don't invent or restate that split yourself if the repo already states it
  somewhere — point at wherever it's defined instead of re-deriving it inline in the report.
- Suggest the pointer-form replacement in the doc that should stop restating (a one-line
  cross-reference), not a full rewrite — same "propose, don't diff" limit as the other checks.

**Circular pointers are a first-class finding here, independent of length.** Two docs that each
say "see the other" for the same fact — so it lives in neither — are the doc↔doc dual of the
duplication above; flag them the same way, quoting both pointers. The Sprawl playbook names this
trap too (step 7), but only inside the AGENTS.md-over-threshold path, so a circular pointer
between two _short_ docs would otherwise slip through. It's just as broken at any length, so it's
caught here regardless of either doc's size.

**Stale issue-ref an ADR now owns.** Once a decision has an ADR (`docs/adr/NNNN-*.md`), later
docs should cite the ADR (`see docs/adr/0003-…md`), not the originating issue — the doc-home
map's rule as ADRs accumulate. Flag a `#N` pointer used to _justify a settled decision_ when an
ADR covering that decision exists, and propose repointing it at the ADR. Stay conservative: a
`#N` referencing live or tracking work (an open issue, a follow-up, a bug still in flight) is
fine and must not be flagged — only a decision's why-pointer that an ADR now owns is the target,
same "quiet on noise" bar as the duplication check. These report under Cross-doc replication too.

Scope stays to the docs an agent relies on for context — AGENTS.md, README.md, top-level
`docs/*.md` — not general repo-doc linting. Don't descend into `docs/` subdirectories (e.g. an
`adr/` archive of point-in-time decisions is expected to reference or echo AGENTS.md/README
content by nature, not drift by accident) and don't extend this check to CHANGELOG.md,
per-tool READMEs, or code comments.

## Repo-fact-in-definition check

The role↔repo seam's drift detector: repos own their conventions, agent definitions encode only
the procedure for discovering them. The seam and its one-question test live in the agents repo's
`docs/operating-model.md` ("The role↔repo seam") — apply that test to each load-bearing line of
every agent definition in scope; don't re-derive it here. Typical shapes that fail it: a concrete
branch name, a commit-type or label list, a CI or build command, a directory layout, an issue
template's field list — any value the definition would act on that the repo, not the role, owns.

A repo fact quoted as an illustrative example inside a discovery instruction ("e.g. `main`") is
fine; a hardcoded value the agent would act on without discovering it is the target. Same
quiet-on-noise bar as the Cross-doc replication check: when in doubt, don't report it.

Each finding quotes the line, names the repo fact it encodes, and proposes the discovery-form
rewrite — same format as the Contradictions check, this is not a new report shape.

## Report

Emit one structured markdown report directly in this response:

```markdown
# Rules Audit

No edits made — this is a proposal only.

## Contradictions

(ranked most-confident first, or "None found.")

## Sprawl

(ranked, or "None found.")

## Restated enforcement

(ranked, or "None found.")

## Cross-doc replication

(ranked, or "None found.")

## Repo facts in definitions

(ranked, or "None found.")

No edits made — this is a proposal only.
```

Each item is self-contained: what's wrong, where (file + quote), and a proposed direction to
resolve it — a suggestion, not a diff, since this skill cannot write.

## Non-goals

The two maintenance judgment gates from `README.md`'s "Maintenance discipline" —
_add a rule only after it would have prevented an actual mistake_, and _remove a rule once it's
followed without being told_ — stay human calls. Don't attempt to apply either; this skill only
surfaces contradictions and sprawl for a human to weigh.
