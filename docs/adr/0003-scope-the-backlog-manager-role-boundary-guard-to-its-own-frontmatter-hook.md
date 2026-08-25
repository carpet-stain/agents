# 0003. Scope the backlog-manager role-boundary guard to its own frontmatter hook

Date: 2026-08-25

## Status

Accepted

## Context

Epic #43 converged (2 review rounds) on enforcing the backlog-manager role boundary — nothing
mechanically stops `git commit`/`push`/`gh pr create` from a session with Bash and working
credentials. The converged design (#46): a `CLAUDE_AGENT_ROLE=backlog-manager` marker set by
every launcher of the role, read by a global `PreToolUse` command hook in `~/.claude/settings.json`.

Implementing #46 required finding where that global hook and marker-threading would actually live.
`carpet-stain/agents` is submodule-only (no runtime `~/.claude/settings.json` of its own — see
README's "Use" section), so the hook and the local-launcher marker discipline would have to live in
`carpet-stain/dotfiles`, and the hosted spawn point (`agent-runner.yml`, also dotfiles) would need
`CLAUDE_AGENT_ROLE` threaded into its `claude -p --agent backlog-manager` call.

Before implementing that, current Claude Code docs (fetched during #44/#46) surfaced a simpler
native mechanism: a subagent's own frontmatter `hooks` block. Per the sub-agents doc, frontmatter
hooks "fire when the agent is spawned as a subagent... and when the agent runs as the main session
via `--agent`" — i.e. exactly the local `claude --agent backlog-manager` case #46 targets, with the
hook definition living right next to the role it guards.

## Decision

Add the `PreToolUse` guard directly to `agents/backlog-manager.md`'s own frontmatter, scoped
automatically to this agent. Drop the `CLAUDE_AGENT_ROLE` marker and the global
`~/.claude/settings.json` hook — no dotfiles change needed for the local path: dotfiles already
deploys this file's content as-is via its existing `~/.claude/agents` whole-dir symlink (no
per-launcher wiring to add or forget).

For the hosted path (`agent-runner.yml`), the guard does not apply: that job symlinks this file
into the checked-out repo's own project-level `.claude/agents/`, and per the permissions doc's
"what runs before you trust a folder" table, a project-level subagent's frontmatter hooks are "not
used, and no dialog is offered" under `claude -p` in an untrusted folder (a fresh CI checkout is
never pre-trusted). Verified directly against `agent-runner.yml`: its `claude -p --agent
backlog-manager` spawn step carries no `GH_TOKEN`/`GITHUB_TOKEN`/`AGENT_PAT` in its environment (the
PAT is scoped only to the later "post response" step), so `git push`/`gh pr create` fail at auth
regardless of any hook. That existing credential scoping is the hosted backstop — no code change
needed there either.

Caveat: "frontmatter hooks fire for the standalone `--agent` case" is doc-sourced, not verified
empirically this round — attempts to test it directly (spawning a nested `claude -p --agent
test-guard` session) were correctly blocked by this session's own auto-mode classifier as
sandbox-less sub-agent spawning. `backlog-manager.md`'s own `mcpServers` field carries a comment
noting a _different_ frontmatter field (`mcpServers`) was verified to behave unlike its docs at the
time (dotfiles#542) — worth a real local check before leaning on this further.

## Alternatives considered

- **`CLAUDE_AGENT_ROLE` marker + global `~/.claude/settings.json` hook (#46's original design)** —
  rejected: requires a dotfiles-side hook plus every present and future launcher of the role
  (local wrapper, `agent-runner.yml`) to remember to set the marker — one missed launcher silently
  reopens the gap. Also doesn't fit `carpet-stain/agents`, which ships no runtime settings of its
  own; the whole mechanism would live in a different repo than the role definition it guards.
- **Also thread `CLAUDE_AGENT_ROLE` into `agent-runner.yml` "for defense in depth"** — rejected for
  now: the hosted spawn step already has no working git/gh credential in its environment, so a
  second guard there has no failure mode to catch. Revisit if that credential scoping ever changes.

## Consequences

- The guard ships as part of the portable role definition — any future consumer of
  `carpet-stain/agents` gets it automatically, not just dotfiles.
- Nothing in `carpet-stain/dotfiles` needs to change for this guard to take effect locally, beyond
  the routine `claude/global` submodule pointer bump that already ships any change here.
- The hosted path's protection remains implicit (credential scope), not a mechanical hook — if
  `agent-runner.yml` ever starts granting the spawn step a working PAT, this ADR's premise breaks
  and #46's acceptance criterion for the hosted path needs re-examining.
- Revisit if the "frontmatter hooks fire under standalone `--agent`" claim turns out false on
  empirical check — the guard would need to move to `SubagentStart`/a wrapper script instead.
