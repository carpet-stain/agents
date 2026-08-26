# The agent design framework

The full set of dimensions a well-designed agent must answer — the audit rubric for the roster.
Division of labor with its sibling doc: **this framework asks, `operating-model.md` answers,
audits measure the distance.** It is a rubric, not a decision record: where an answer is decided
it cites the home (a `carpet-stain/dotfiles` ADR or an operating-model section), never restates;
where nothing is decided, the dimension stays an open question. Adopting a position on an open
dimension happens in an ADR, not here.

Each dimension carries a short statement of what it covers, pointers to decided answers where
they exist, and its **audit questions** — the fixed checklist every per-agent audit instantiates.
The questions don't change between audits, so the four matrices (backlog-manager, plan-reviewer,
implementor, code-reviewer) stay comparable. The matrix form itself is defined at the end; the
instances live in the audit epics, not here.

## 1. Existence

### D1. Dimension zero — should this be an agent at all

The simplest-thing ladder: a single LLM call → a deterministic workflow → an agent, in that
order, and the deterministic rung is checked first every time. A gate, hook, or CI check that can
enforce the outcome with certainty always beats a model that can drift.

Decided: operating-model.md "Deterministic work stays deterministic" and the structural-edge
filter (structural edge × invocation fit × latency-viable); dotfiles ADR-0025.

- Does this role clear all three gates of the structural-edge filter?
- What deterministic mechanism was considered and why is it insufficient?
- Which parts of the role's job could still be pushed down into tooling?

### D2. Charter and non-goals

One role, one job, stated in a sentence — plus the explicit list of what the role does _not_ do,
so scope creep is a diff against a written boundary rather than a feeling.

Decided per role in `agents/*.md` (e.g. the backlog-manager's "you do not write code" boundary,
enforced by its frontmatter hook — agents ADR-0003).

- Can the role's job be stated in one sentence, and does the definition state it?
- Are non-goals written down, and is the boundary enforced or only described?
- Does anything in the definition belong to another role's charter?

## 2. Core loop

### D3. Context engineering

Context is a finite attention budget, not a bag. Four operations — write, select, compress,
isolate — plus just-in-time retrieval via lightweight identifiers over preloading, and known
failure modes (poisoning, distraction, confusion, clash).

Partially decided: the rules tree's layered GATE/LOCAL-WINS structure (dotfiles ADR-0008) is
context selection; the pointer-layer memory contract (dotfiles ADR-0033, carried through 0036/0046)
is compression by construction. No decided position on compaction or long-horizon context.

- What loads into the role's context by default, and what is retrieved just-in-time?
- Is anything preloaded that a pointer would serve?
- How does the role behave as its context fills — is there a compaction or notes strategy?

### D4. Control-flow ownership

Which decisions code owns versus the model. Sequencing, exit checks, retries, and workflow state
are deterministic problems; an agent given them drifts and burns tokens. The model owns judgment;
everything ownable by code moves there.

Decided: operating-model.md "Orchestration is deterministic — keep it off the LLM" (workflow
state in GitHub labels, not agent context); dotfiles ADR-0042's deterministic tripwires.

- Which control-flow decisions does the role's harness own, and which does the model improvise?
- Is workflow state externalized (labels, files, issue state) or held in the model's context?
- What currently-improvised sequencing could move into code or a skill?

### D5. Planning

Planning decoupled from execution, and the plan validated before the run — errors compound
(95% per step ≈ 60% over ten), so catching a bad plan is worth an order of magnitude more than
catching a bad step.

Decided: the issue-stage plan gate (dotfiles ADR-0025, amended by 0042) — the plan is reviewed
as an artifact (`needs-plan-review` → `plan-approved`) before any implementation session starts.

- Does the role separate plan from execution, or interleave them?
- Is the plan validated by a separate context before it runs?
- What happens when execution diverges from the plan — is the deviation journaled?

### D6. Tool surface — agent-computer interface

Tool design deserves prompt-level effort: few tools, unambiguous names, poka-yoke shapes that
make the wrong call hard to express. The inventory is measured (which tools actually get called),
not accumulated.

Partially decided per role: tool lists in `agents/*.md` frontmatter; the plan-reviewer's
read-only GitHub MCP scoping (agents#27). No decided method for tool-inventory review.

- Is every tool in the role's list actually used, and does anything missing force workarounds?
- Can the most dangerous tool call be expressed by accident, or does its shape prevent it?
- Are tool errors surfaced in a form the model can act on?

### D7. Memory

The memory triad — semantic (facts), episodic (what happened), procedural (how to) — and
selection, the hard half: what to recall when, and what never to store because a durable doc
already owns it.

Decided: hosted per-role stores, never pooled (dotfiles ADR-0046, superseding 0043); the
pointer-layer content contract (ADR-0033 via 0036); write-time contract in
`agents/backlog-manager.md` with `audit-memory` as the detection backstop.

- Which of the triad does the role's store actually hold, and is each entry a pointer or a copy?
- What is the selection mechanism — how does a past lesson reach a future session?
- Is anything in memory that a durable home (ADR, issue, AGENTS.md) should own?

### D8. Grounding discipline

Live state over recall: shared mutable state (issues, branches, labels, files) is fetched fresh
before acting, never trusted from memory or summary. A stale premise poisons everything downstream.

Decided: rules/universal/ai-collaboration.md "Verify, Don't Trust"; the "learn this repo before
acting" preamble pattern in `agents/backlog-manager.md`.

- What shared mutable state does the role act on, and does it re-fetch before every action?
- Where has the role been caught acting on stale recall, and what now prevents it?
- Do its memory entries date-stamp what was true when written?

## 3. Safety

### D9. Permissions and blast radius

Least privilege by construction: the credential scoped to what routine work needs, elevation
explicit and per-action, and the worst reachable outcome bounded before the role runs at all.

Decided: scoped-down `gh` tokens (rules/platform/github.md; AGENTS.md credential pattern);
per-role memory credentials (dotfiles ADR-0046); read-only MCP for the plan-reviewer (agents#27).

- What is the worst action the role's credentials permit, and is it needed for routine work?
- Is elevation explicit and per-action, or ambient?
- Are the role's writes bounded to its own artifacts (its store, its comment surface)?

### D10. Adversarial robustness

Layered guardrails against hostile or malformed input: prompt injection via the content the role
reads (issue bodies, PR comments, fetched pages), PII handling, and per-tool risk rating gating
which calls get checked.

Open — no decided position. The roster today reads untrusted GitHub content with no injection
screen; nearest prior art is OpenAI's layered-guardrail and tool-risk-rating model (see Sources).

- What untrusted content does the role ingest, and what happens if it contains instructions?
- Are tools risk-rated, with the high-risk ones gated by extra checks?
- Does any guardrail exist at a layer other than the prompt?

### D11. Verification and escalation

An independent verifier in a separate context — a model grading its own output in its own context
misses most of its mistakes — plus structured escalation with named triggers for when a human
must be pulled in.

Decided: the diamond (operating-model.md "Orchestration lessons"); the plan-reviewer as
separate-context verifier (dotfiles ADR-0025/0042); the human merge as the terminal gate
(operating-model.md core invariant).

- Who verifies the role's output, and is that verifier a genuinely separate context?
- Are escalation triggers named (failure thresholds, high-risk actions), or ad hoc?
- Can the role's work take irreversible effect without a human approval?

### D12. Termination

Every loop ends by construction: exit conditions, iteration caps, and budget tripwires that halt
to a human rather than degrade silently.

Decided for the one live loop: dotfiles ADR-0042's tripwires (max rounds, max depth, cycle guard,
spawn cap, one-writer-per-artifact, budget dead-man's switch). Undecided for roles outside it.

- What are the role's exit conditions, and are they checked by code or by the model's judgment?
- What caps bound iteration, spawn count, and spend — and what happens on trip?
- Can the role stall or loop in a way nothing detects?

## 4. Operations

### D13. Identity and attribution

Each agent is a first-class team identity: agent as git author (honest blame), human merger as
accountability anchor, and voice matching authorship — agents read as AI, never impersonate.

Decided: dotfiles ADR-0035 (named identities), ADR-0037 (read as AI), ADR-0038 (author/ship
split); operating-model.md "Identity, authorship, voice".

- Does every artifact the role produces carry its identity in the author field?
- Does its prose read as the agent, or drift toward impersonating the maintainer?
- Is the accountability anchor (who shipped it) distinguishable from who authored it?

### D14. Observability and evals

Failure-mode taxonomy over generic metrics: planning failures, tool failures, efficiency
failures — counted per role, so a definition edit targets an observed failure class rather than
a hunch.

Open — the telemetry track (dotfiles#545) is unbuilt. Intended feed: author-field provenance,
cost/token spend per agent+task, review rounds, stall points (operating-model.md "Manageable and
measured").

- Where would an operator see this role's failure classes today?
- Is spend attributable to the role and task?
- Has any definition edit ever been driven by measured failure data?

### D15. Cost and model matching

Model and effort matched to task risk: judgment work where being wrong is expensive gets the
capable model; mechanical, verifiable work gets a lighter one. Baseline with the best model,
downgrade on evidence.

Decided as a rule: rules/universal/ai-collaboration.md "Match Model And Effort To Task Risk";
applied per role in `agents/*.md` frontmatter (model + effort with the rationale in a comment).

- Is the role's model/effort choice recorded with its reasoning, and is it still right?
- Which of the role's stages could run on a lighter model without quality loss?
- Is there a cheap warm-start path (skills, memory) that substitutes for raw model capability?

### D16. Interruptibility and state

Launch, pause, and resume as first-class: execution state externalized so a run can be
interrupted, inspected, and continued — not held hostage in one process's context.

Partially decided: workflow state in GitHub labels and issue threads (operating-model.md), the
thread as the reviewer's cross-round memory (dotfiles ADR-0042). No decided model for pausing or
resuming an in-flight session.

- If the role's session dies mid-task, what is lost and what resumes from external state?
- Can a human inspect and redirect a run in flight?
- Is business state (the artifact) separate from execution state (the run), or conflated?

### D17. The definition's own lifecycle

The agent's definition is a versioned, reviewed artifact: a performance review is a PR to its
`agents/*.md`, one fix propagates to everyone, and the definition is audited against this rubric
rather than grown by accretion.

Decided: operating-model.md "Manageable and measured"; this repo's extraction as the shared,
provider-neutral home (dotfiles ADR-0039, agents ADR-0002).

- When was the definition last changed, and was the change driven by observed behavior?
- Does the definition carry provenance for its load-bearing lines (pointers, verified-at notes)?
- Is anything in it dead — a rule for a situation that no longer exists?

### D18. Interfaces and orchestration

How the role is invoked and composed with others: invitation as the authorization,
substrate-mediated cross-role invocation, and the pattern catalog (chaining, routing,
parallelization, orchestrator-workers, evaluator-optimizer) chosen at the lowest complexity
that works.

Decided: operating-model.md "Invocation — invitation is the authorization" and "Orchestration
lessons"; dotfiles ADR-0042. Substrate: dotfiles#576 (unbuilt).

- What are the role's invocation surfaces, and can it ever self-invoke?
- Do its cross-role interactions go through the substrate, or leak into nested subagents?
- Is each orchestration edge real — does the downstream step read the upstream output?

## The gap matrix

Each per-agent audit instantiates one matrix: a row per dimension, one of three states, one
pointer per cell. Three states, no maturity scoring — a roster of four doesn't need levels.

- **covered** — the dimension has a decided answer that the role demonstrably implements; the
  cell points at the owning ADR, doc section, or definition line.
- **partial** — an answer exists but the role implements it incompletely, or only part of the
  dimension is decided; the cell points at what exists and names what's missing.
- **uncovered** — no answer for this role; the cell names the gap (and the tracking issue, once
  one is filed).

A cell is a pointer, never prose — the argument lives in the ADR or issue it points at.

| Dimension          | State                           | Pointer / gap           |
| ------------------ | ------------------------------- | ----------------------- |
| D1. Dimension zero | covered \| partial \| uncovered | ADR / issue / named gap |
| …                  |                                 |                         |

The four instances (backlog-manager, plan-reviewer, implementor, code-reviewer) live in their
audit epics, filed after this doc lands — none is instantiated here.

## Sources

External prior art this rubric distills, kept so revisions don't re-derive it. Cite, don't
restate — the concept names above (write/select/compress/isolate, the memory triad, ACI,
dimension zero) are the only summaries carried inline.

| Source                                                                                                                                         | Contributes                                                                                |
| ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [Anthropic — Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)                                       | Dimension zero; workflow pattern catalog; ACI — tool design deserves prompt-level effort   |
| [Anthropic — Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)                 | Context as finite attention budget; just-in-time retrieval; long-horizon techniques        |
| [12-Factor Agents](https://github.com/humanlayer/12-factor-agents)                                                                             | Deterministic/probabilistic split; pause/resume; unified state; small focused agents       |
| [Chip Huyen — Agents](https://huyenchip.com/2025/01/07/agents.html)                                                                            | Plan validation before run; compounding-error math; failure-mode taxonomy for evals        |
| [OpenAI — A Practical Guide to Building Agents](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf) | Layered guardrails; per-tool risk rating; human-intervention triggers                      |
| [Microsoft — AI Agent Orchestration Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)       | Orchestration catalog; lowest-complexity-that-works; maker-checker caps                    |
| [LangChain — Context Engineering](https://blog.langchain.com/context-engineering-for-agents/)                                                  | Write/select/compress/isolate; context failure modes; memory triad, selection as hard half |

What none of them cover — every one designs product agents, not team-member agents — is the surplus
this repo's model adds, kept above as first-class dimensions: identity and attribution (D13),
grounding discipline in shared mutable state (D8), the definition's own lifecycle (D17), per-role
memory ownership (D7), and forcing functions over prose rules (threaded through D2, D4, D12).
