---
name: grilling
description: >-
  Extracts decisions in dependency order before committing to a plan, instead of guessing a
  batch of assumptions. Maps the open decisions as a design tree and asks each round's
  frontier — every question whose prerequisites are settled — with a recommended answer per
  question; looks up anything discoverable in the environment itself rather than asking, and
  doesn't act until the frontier is empty. Use when scope, structure, or approach is genuinely
  undecided and guessing would waste a round — shaping a new epic, splitting an overgrown
  issue, defining a spike's question and deliverable, weighing a spike's verdict, or pre-gating
  an issue with thin acceptance criteria. Not for routine, already-clear work.
---

# Grilling

A protocol for extracting decisions, not a form to fill out. The failure mode this replaces:
guessing a batch of assumptions up front and burning a round when one is wrong.

Map the open decisions as a **design tree** — every decision branches into the decisions that
hang off it — and work it in **rounds**. The **frontier** is every decision whose prerequisites
are already settled: the questions askable now without guessing at answers not yet heard.

## Rules

1. **Facts are yours; decisions are the human's.** Anything discoverable from the
   environment — an existing file, a label taxonomy, a past decision in memory, prior art in
   the repo — isn't a question. Look it up. When a lookup is long-running, dispatch a subagent
   and don't block the round on it: only the questions downstream of its answer wait; ask the
   rest of the frontier now.
2. **Ask the whole frontier each round — and nothing past it.** A question whose answer depends
   on another question still open this round belongs to a later round, not this one. Then wait:
   each round's answers reshape the tree, settle prerequisites, and push the frontier outward.
   Recompute and ask the next round.
3. **Every question carries a recommendation.** State the decision, your recommended answer,
   and why in a sentence or two. The human is confirming or redirecting a specific call, not
   opening a blank design discussion.

   ```text
   ❓ **Q1** — **<decision title>**: <the question, choices included where they help>

   ➡️ <recommended answer, with the why>
   ```

4. **Don't act until the frontier is empty.** No drafting the epic body, splitting the issue,
   or writing the plan while any decision is open — grilling ends when the tree is fully
   visited, not when you get tired of asking.

## When to stop

An empty frontier ends the interview: every branch visited, nothing left silently assumed —
hand off to whatever comes next (drafting the epic, writing the split, defining the spike).
Don't manufacture questions once nothing is actually undecided.
