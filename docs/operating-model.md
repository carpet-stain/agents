# The agent operating model

How this project treats AI agents: as **managed team members**, not personal tools — cohesive with
existing engineering ceremonies, shared across contributors, and manageable. This is the decided
**philosophy layer**. The concrete machinery that instantiates it — the full roster, the
event-driven substrate, the telemetry pipeline — is still incubating in `carpet-stain/dotfiles#545`
(the proving ground) and exports here as it firms.

Each decision has one home: a `carpet-stain/dotfiles` ADR or issue. This doc is the cohesive map
over them, not a second copy — it cites, it doesn't restate. Sections are tagged **[Decided]**
(ADR-backed, stable) or **[Directional]** (agreed intent, still forming — expect it to move).

## Core invariant

**The human gates the decision, not the labor.** Agents review, draft, critique, and fill tickets
unattended — but nothing they produce has irreversible effect until a human approves and merges.
Every agent, every mode. This is the fixed point the rest hangs off.

**[Directional] trajectory, decided at charter (agents#55/#57):** the invariant's merge leg is
substrate policy — the recorded intent is a future flip to auto-merge for spec-verified work,
gated by a blocking code-reviewer. The flip ships as a ruleset change plus superseding ADRs
(ADR-0025's advisory clause via agents#67; this invariant's merge leg via an ADR at flip time).
Until those land, the invariant binds unchanged.

## Identity, authorship, voice — [Decided]

Each agent is a first-class team identity (`implementor`, `backlog-manager`, `plan-reviewer`, …),
never the vendor. Authorship splits cleanly: the agent is the git **author** (honest blame for who
did the work), the **merger** is the accountability anchor (committer + `merged_by`). The prose
layer mirrors the git layer — `voice = agent` (agents read as AI, never impersonate a human) is the
same honesty as `author = agent`.

→ dotfiles ADR-0035 (named identities), ADR-0037 (read as AI), ADR-0038 (author/ship split),
dotfiles#544.

## The edge is per-role — memory is the backlog-manager's moat — [Decided]

A team agent beats a dev's private session on a structural edge a cold session can't replicate —
and the roster audits (agents#53) showed the edge differs per role: **accumulated memory** (the
backlog-manager), **separate-context independence** (plan-reviewer and code-reviewer — both
deliberately store-less; the thread is their memory, reaffirmed at charter in agents#56/#57),
**holding the gate** (the blocking code-reviewer). A persona without _an_ edge is a sock puppet.
Where a role's memory exists, it is owned **per role**,
never shared across roles — each agent has a private, role-scoped store with its own credentials, so
read/write scoping holds by construction with no enforcement layer to build. The shared record
_across_ roles is the GitHub artifacts themselves: **issue body = destination, thread = journey**,
one home per fact. A role needing more than the issue carries invites the backlog-manager (the
information broker), never another role's memory.

→ dotfiles ADR-0033 (pointer-layer content contract), ADR-0036 (MCP knowledge-graph), ADR-0046
(hosted per-role stores — supersedes ADR-0043's two-tier shared model). Build track: dotfiles#602.

## What earns a shared agent — the structural-edge filter — [Decided]

Build a team agent only where it has an edge a private session lacks. A role clears the bar only if
it passes all three gates: **structural edge** (≥1 of accumulated team memory / structural
independence / being the artifact-of-record) × **invocation fit** (a natural invitation surface,
human-gated, never self-invoking) × **latency-viable**. No edge → don't build it (no standup-bot, no
lint-agent). Value that's per-user and in-session → the implementor pattern below.

**Team-wide by default; the implementor is the individually-invoked exception** — same definition
and memory for everyone, but the implementor lives in each contributor's own session.

Sharpest case: the **backlog-manager is the cross-stakeholder intake funnel** — the one place every
inbound stream (eng, SRE, product, security, perf, feedback) converges, so it alone can dedupe
across them and propose one priority. It _proposes_; the human _disposes_.

→ dotfiles ADR-0042 (roster); dotfiles#560 (incubating machinery). Promoted [Directional] →
[Decided] 2026-08-26: the three-gate filter survived four unmodified applications in the roster
audits (agents#53).

## Invocation — invitation is the authorization — [Decided stance / Directional mechanism]

Agents act **only when invited**, never self-invoke — the guard against agent spam. Three modes:
**lifecycle-event** (code-reviewer on PR-review-request, UAT on CI-green), **ceremony**
(backlog-manager in grooming: transcript → tickets), **on-demand**.

**Cross-role invocation is substrate-mediated; intra-role parallelism is in-session.** No agent
spawns another _role_ as a nested subagent — a nested subagent runs under the caller's process and
credentials, so per-role identity and memory ownership can't hold there. Cross-role needs are
invitations in the substrate (@-mention/comment/label), and the runner spawns the invited agent as a
first-class session under its own identity. Carve-out: same-role read-only research/explorer
subagents stay in-session — they cross no lane, need no identity, pay no event-loop latency.

Agent→agent auto-invocation (backlog-manager → plan-reviewer is the live case) fires only on
enumerated, idempotent, deduped triggers, and every loop carries hard deterministic tripwires: a
max round-count, a max invocation depth, a cycle guard, a spawn cap, one-writer-per-artifact, and a
**budget dead-man's switch** (wall-clock or token/cost ceiling) that halts to a human on trip.

→ dotfiles ADR-0042 (roster/operating model; amends ADR-0025's plan-gate). Substrate: dotfiles#576
(unbuilt). The loop is store-less by design — the thread is the reviewer's cross-round memory.

## Adoption by ergonomics, not enforcement — [Decided]

Adoption comes from being the easiest path that produces the of-record artifact, not from policing.
"Unskippable" is emergent, not a wall. The recurring worry — a dev hands push credentials to their
own agent and bypasses the team implementor — hides a false goal: **enforce the outcome, not the
tool**. Using your own agent is no different from using a different editor; the team enforces that
the PR passes review, and every PR clears the same tool-agnostic gates (CI, code review, branch
protection, the human merge) whatever produced it. A scoped push token bounds the blast radius to
what the dev already has.

The team agent wins on merit, three axes: **quality** (the memory moat — no rediscovery), **cost**
(a warm start + tested skills burns far fewer tokens than a cold one-shot), **capability** (it's a
**superset** of a general agent — the full toolset stays available; the moment it's a locked-down
subset, bypass becomes rational and adoption dies). Save on the known, spend on the unknown;
efficiency funds freedom. Latency is the kill-switch — a slow loop fails regardless of correctness.

## Deterministic work stays deterministic; agents are the judgment layer — [Decided]

Anything a hard config, hook, ruleset, lint rule, or CI check can enforce with certainty lives
there — never an agent. It's cheaper, exact, driftless, token-free, and it constrains a human and an
agent identically. Release gates → CI + branch-protection rulesets; formatting → hooks; conventions
→ the check that rejects them. So no devops agent, no release agent, no lint agent — the gate does it
better. Shift-left tooling isn't a casualty of agents; it's the substrate they stand on, and every
deterministic rule pushed down into tooling is one less thing a probabilistic model can get wrong.

Two domains, don't conflate them: **adoption** wins by ergonomics (soft — the plan-review gate is
discipline, not a wall); **correctness** gets a hard wall (a CI check). Each is right for its kind.

**The enforcement ladder — [Decided].** Rules land on the highest rung worth reaching:
substrate-native (rulesets, native mechanics, required CI) → third-party tooling (lefthook,
gitleaks) → own code (`scripts/`) → agent hooks → model judgment in a gate (an agent verdict
wired to a substrate enforcement point) → prose, last, ideally with a deterministic detection
backstop. Corollary: the SDLC is invariant when agents join — the process doesn't change, but
gaps a human covered implicitly must be surfaced and explicitly covered on a rung (or a named
human gate) before the seat counts as filled. → agents ADR-0003 (the why and the rejected
alternatives).

→ dotfiles ADR-0025 (advisory pipeline: soft plan gate + `pr-code-review`).

## Provider-agnostic by design — [Directional]

Definitions, rules, personas, and memory should be portable across providers (Claude, Codex, and the
rest), never locked to one. Keep the _content_ neutral — personas, process, acceptance, the MCP
knowledge-graph memory, `AGENTS.md` as the neutral home over a Claude-specific `CLAUDE.md` — and
isolate provider coupling to a thin adapter/binding layer. Same "domain before transport" discipline:
the agent's meaning is the stable core, the provider binding is transport. This repo _is_ the neutral
core; Claude Code is the one concrete binding today.

→ dotfiles ADR-0039 (this repo's extraction as a submodule).

## The role↔repo seam — agents discover conventions, never encode them — [Decided]

Sibling to the provider↔content seam above: repos own their conventions — lint, CI,
commit/branch/PR structure, issue templates, code style — enforced repo-side (rulesets and CI,
agents ADR-0003 rungs 1–2); agents **discover** them at runtime. A definition may encode the
_procedure for discovering_ a repo's conventions, never the conventions themselves. The
one-question test: **would this line change if the repo changed? Then it belongs to the repo.**

The practice already lives at the seam's corners — the implementor's Phase 0 discovery
(`agents/implementor.md`, `skills/orient`), `implement-issue`'s zero-mechanics-restated step, the
backlog-manager's learn-this-repo-first preamble and issue-template deference, the rules tree's
LOCAL-WINS headers. This section is their shared name, not a fifth copy.

Repo-side obligation: LOCAL-WINS only works when there's a local to win — each managed repo owes
its own workflow doc (`rules/tools/git.md`'s COMPOSE step). A repo without one inherits the
generic baseline as de-facto policy; that inheritance must be a visible choice, recorded in the
repo, not silence.

Drift detection: the `audit-rules` skill's repo-fact-in-definition check (prose + deterministic
detection backstop — ADR-0003 rung 6); the design framework asks the same question per
definition under D17.

→ agents#84 (naming); agents ADR-0003 (enforcement-side placement).

## Manageable and measured — [Directional]

A manager manages an agent two ways: (a) **editing its shared, versioned definition** — an agent's
"performance review" is a PR to its `agents/*.md`, and one fix propagates to the whole team at once;
(b) **reading telemetry** — a two-way loop that improves the agent (where it fails or gets corrected)
_and_ the humans (where they struggle using it → prompt-eng training). Metrics: cost/token/model
spend per agent+task, review rounds, where work stalls — fed by the author field and provenance
trailers.

→ Observability track (unbuilt, dotfiles#545).

## Orchestration lessons (multi-agent) — [Directional]

Constraints carried from external multi-agent practice onto our own tracks:

- **The diamond.** Parallel workers → a _separate-context_ verifier → one owned merge. A model
  grading its own output in its own context misses most of its mistakes; the plan-reviewer is a
  separate subagent for exactly this reason.
- **Split only what splits.** Parallel agents win on genuinely independent lanes and lose on
  sequential work where each step needs the whole picture. More agents is not a strategy.
- **One owner of the merge.** Uncoordinated parallel agents amplify each other's errors.
- **Gate where undo is expensive**, not at every step — route irreversible edges (deploy, publish,
  delete) through approval; let deterministic/verifiable steps self-advance.
- **Delete fake edges.** An arrow between two jobs is real only when the second reads the first's
  output; everything else runs in parallel.
- **Orchestration is deterministic — keep it off the LLM.** Sequencing, exit checks, and retry are
  deterministic problems; a model given them drifts and burns tokens. Workflow state lives in GitHub
  labels (`needs-plan-review` → `plan-approved`), not an agent's context.
- **Review the artifact, not only the plan.** Separate-context review of completed artifacts caught
  real errors in every roster audit that ran one (agents#54–#57) — the diamond applies to outputs,
  not just approaches.
- **Working state is ticket-scoped, public, and dies at completion.** The reviewer's thread, the
  implementor's PLAN.md, the review dance's PR thread — one pattern, three surfaces. Never private
  state: reasoning that influences the next round lives where a human can audit it.
- **Escalate up a ladder, exhausted in order.** Self-resolution → the reviewing agent → the
  backlog-manager → a human (agents#55). Minimal human escalation is a goal, not an accident.
- **Check the substrate for the primitive before designing one.** GitHub's native review-request
  gave the code-reviewer its invitation, re-invitation, verdict vocabulary, and wake state for
  free — the plan-reviewer must build the same from parts (agents#57 vs agents#64/#65).

## Decision index

Every operating-model decision, its home, and its status. The ADRs live in `carpet-stain/dotfiles`.

| ADR  | Decision                                                                                        | Status                                                        |
| ---- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| 0008 | Agent-config rules: layered tree, GATE / LOCAL-WINS / COMPOSE                                   | Accepted                                                      |
| 0016 | Provenance-before-removal (Chesterton's Fence) for agents                                       | Accepted                                                      |
| 0025 | Advisory review pipeline: issue-stage plan gate + pr-code-review                                | Accepted (plan clause → 0042)                                 |
| 0033 | Memory is a pointer layer — the content contract                                                | Superseded by 0036 (content contract carried forward, → 0046) |
| 0035 | Deliberation as named agent identities, shipped work as the maintainer                          | Accepted (clauses → 0037/0038/0048)                           |
| 0036 | MCP knowledge-graph memory, private local store                                                 | Accepted (write clause → 0043; local-store model → 0046)      |
| 0037 | Agents read as AI (amends 0035 voices)                                                          | Accepted                                                      |
| 0038 | Agent authors, maintainer ships (amends 0035 shipped-work)                                      | Accepted                                                      |
| 0039 | Extract agent definitions to the agents repo (main-tracking submodule)                          | Accepted (→ agents ADR-0002)                                  |
| 0040 | Per-repo backlog + virtual multi-repo project overlay                                           | Accepted                                                      |
| 0042 | Shared-agent roster and operating model (amends 0025 plan-drafting)                             | Accepted (roster → 0046)                                      |
| 0043 | Per-role memory write-ownership (amends 0036 shared-write)                                      | Superseded by 0046                                            |
| 0046 | Hosted per-role agent memory over MCP-HTTP (amends 0033, 0042; supersedes 0043's tier)          | Accepted (roster runtime-homes → 0048)                        |
| 0048 | Hosted GitHub Actions runtimes for plan-reviewer + self-driving implementor (amends 0035, 0046) | Accepted                                                      |

## Scope and residency

This doc is the **decided philosophy layer**, exported to agents ahead of the full operating-model
export. The line: agents owns the stable framework (this doc) + the agent definitions, rules, and
skills; `carpet-stain/dotfiles#545` remains the proving ground for the still-incubating machinery
(roster #560, event substrate #576, telemetry) and holds provenance. The concrete
ceremonies/roster/telemetry export follows once the substrate is real — deliberately gated, so a
still-forming model isn't frozen prematurely.
