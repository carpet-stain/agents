# 2. Vendored agent cloud channel

Date: 2026-08-17

## Status

Accepted

## Context

ADR-0039 (`carpet-stain/dotfiles`) distributes agent definitions as a git submodule symlinked
into `~/.claude/` — a single-workstation, local-CLI channel. `carpet-stain/dotfiles#582`
(Decision 1) requires `backlog-manager` to also work from claude.ai/code web and iOS. Verified
surface fact (Claude Code docs, 2026-08-16): a cloud session loads only **repo-level
`.claude/agents/`** — `~/.claude/agents/` never loads there. So on cloud surfaces an agent has no
definition to load; ADR-0039's channel doesn't reach them.

## Decision

A second, **additive** project-level channel, pull-based and consumer-owned:

- **Pull, not push.** Each consumer repo runs a scheduled + `workflow_dispatch` GitHub Actions
  workflow that checks out this (public) repo, runs `scripts/render-agent.sh`, and opens a drift
  PR using its own `GITHUB_TOKEN` — no cross-repo write credential, no producer-side consumer
  registry.
- **Vendored real files, not a submodule-in-repo.** Cloud reads plain files at
  `.claude/agents/<name>.md`; a gitlink may not init or be readable there.
- **Scope = named-skill closure**, not the whole tree: a vendored agent's persona plus the skills
  it instructs the _in-role_ agent to **run** (a real, walkable edge — e.g. `backlog-manager.md` →
  `grilling`, `groom-backlog`). Skills named only as backstops that a separate fresh-context
  subagent runs (e.g. `audit-memory`, `audit-rules`) are excluded — they never execute in the
  rendered session. **Rules are out of scope for v1**: ADR-0008 loads rules by directory presence,
  not an agent→rule edge, so a "rules closure" would reintroduce the per-repo whitelist that ADR
  already rejected. Whether a repo-committed rules dir loads on cloud at all, and how, is an open
  question — tracked as a separate spike, gating any future rules vendoring.
- **A cloud-channel transform, not a pure copy.** `mcpServers:` frontmatter (and its explanatory
  comment) is stripped, `mcp__memory` is dropped from `tools:`, and a persona's `## Memory` section
  is replaced with an explicit "memory unavailable on this surface" note. A def that still _calls_
  a tool it no longer has is a worse failure than one that never claimed the capability.
- **Owned carve-out only.** The renderer writes and `--check`s exactly `.claude/agents/<name>.md`,
  `.claude/skills/<name>/`, and `.claude/.agents-ref` — never a whole-`.claude/` diff.
  `settings.json` and consumer-local skills (e.g. dotfiles' `verify-nvim-config`, ADR-0039: STAYS
  local) are outside the carve-out by construction.
- **A consumer-pinned drift guard**, not a floating-`main` one: CI runs the renderer in `--check`
  mode against the SHA recorded in the consumer's own `.claude/.agents-ref` — never this repo's
  current `main`. Upstream churn can't redden an unrelated consumer PR; it surfaces only as the
  next scheduled drift PR bumping the pin. **This resolves ADR-0039's SHA-pinning
  deferral (`carpet-stain/dotfiles` ADR-0039) for the cloud channel only** — 0039's deferral still
  stands, unchanged, for the local/submodule channel. The guard no-ops when `.agents-ref` is
  absent (a virgin consumer has nothing vendored yet to check); the first sync PR writes the ref
  and the carve-out atomically, so the two never exist half-populated.
- **v1 ships `plan-reviewer` only.** It is zero-transform (`tools: Read, Grep, Glob`, no
  `mcpServers`, no memory in its body, no named skills), so it proves the full
  pull/render/drift-PR/`.agents-ref` machinery against a clean def with no transform surface.
  `backlog-manager` is explicitly deferred (see Alternatives) — the acceptance "backlog-manager
  loads on cloud" moves to `carpet-stain/dotfiles#602`, alongside the hosted-memory transport
  (ADR-0046) that makes it a _functioning_ cloud agent, not just a loaded one.

## Alternatives considered

- **Push-based sync** (this repo dispatches to every consumer on merge) — rejected: fans a
  cross-repo write credential across every consumer and needs a producer-side consumer registry
  that drifts. Pull with a consumer-owned token mirrors how the submodule channel already pulls.
- **Submodule-in-repo** (a gitlink committed inside the consumer's `.claude/`) — rejected: no
  guarantee a cloud session's checkout initializes or reads through a gitlink. Plain vendored files
  at the exact expected path are the only guarantee.
- **Vendoring `backlog-manager` in v1 with just its `## Memory` section scrubbed** — rejected: its
  memory-tool instructions are also woven into "Groom on a cadence" and "Project scope" (and
  softer in its `groom-backlog`/`grilling` skills). A transform that only rewrites the Memory
  section loads cleanly and then instructs the agent into `mcp__memory` calls whose tool the
  transform already dropped — the load-time failure `mcpServers`-stripping fixes, reappearing
  mid-task instead. Faithfully neutralizing it is unbounded, structure-dependent text surgery
  across the body _and_ its skills — exactly where fragility is worst. Deferred to
  `carpet-stain/dotfiles#602`, where hosted MCP-over-HTTP memory (ADR-0046) lets the def carry a
  _hosted_ `mcpServers` endpoint instead — a clean swap, not surgery.
- **A scheduled cloud canary** (a CI-launched cloud session asserting the def loaded) — rejected:
  reintroduces the same per-consumer credential fan-out the pull-based inversion eliminated (cloud
  auth as a new per-consumer secret), plus an unspecified load-readback mechanism. v1's gate is one
  real, human-run cloud-session verification at vendoring time instead.
- **A per-consumer manifest naming the hosted agent set** — rejected as premature: v1 derives the
  hosted set from the `.claude/agents/*.md` basenames already present in the consumer. A manifest
  returns only if a consumer must host a strict subset of what's present.
- **Drift guard against floating `main`** — rejected: every unrelated consumer PR would redden the
  moment any upstream def changes, for consumers who haven't opted into that change yet. The
  consumer-pinned `.agents-ref` isolates upstream churn to the next scheduled sync.

## Consequences

- Two channels now carry one agent by design: the ADR-0039 submodule (pull-latest `main`) and this
  vendored copy (pinned to a lagging SHA). They differing by the pin lag is expected, not drift.
  On a machine that is both source and consumer (dotfiles), the deployed `~/.claude/agents`
  symlink and the committed `./.claude/agents` vendored copy are two load paths that can
  legitimately disagree — edit the submodule/source to change behavior, never the vendored copy.
- Vendored duplication across every consumer repo is the deliberate trade against ADR-0039's
  single-copy submodule — accepted because it's sync-bot-controlled and drift-guarded, not
  hand-maintained.
- `backlog-manager`'s cloud channel and its "functioning" acceptance (not just "loads") track to
  `carpet-stain/dotfiles#602`.
- The one unhedgeable risk is external: Anthropic changing what a cloud session loads from a
  checkout invalidates this ADR's founding fact. No automated canary covers it (see Alternatives);
  revisit this ADR if that surface fact changes.
- A future rules-vendoring decision depends on the separate cloud-rules-loading spike; this ADR
  makes no claim about rules.

Refs: `carpet-stain/dotfiles#597` (deciding issue, 3 plan-review rounds), `carpet-stain/dotfiles`
ADR-0039 (distribution decision this resolves the pin-deferral of, for the cloud channel only),
`carpet-stain/dotfiles#582` (Decision 1, the requirement this channel serves),
`carpet-stain/dotfiles#602` (backlog-manager's cloud channel + hosted-memory transport),
`carpet-stain/dotfiles` ADR-0046 (hosted memory), ADR-0008 (rules load-all model, why rules are
out of scope here).
