# AGENTS.md

Precedence: this repo's own docs win over the generic agent-config rules where they conflict.

## What this is

See `README.md` for what this repo is and how it's consumed.

<!-- TODO: once claude/{rules,agents,skills} content lands (carpet-stain/dotfiles#567 — see issue
#3's non-goals), expand this with the directory layout and how a consuming repo wires the
submodule in. -->

## Commits — Conventional Commits

> Concrete realization of **git.md** (Commits — Conventional Commits) for this repo.

`type(scope): description`, imperative lowercase subject ≤50 chars (hard limit 72); `type` ∈
feat/fix/docs/style/refactor/perf/test/build/ci/chore; `scope` ∈ `docs`, `scripts` — confirm
before relying on this list, it's thin until real content lands. Breaking change: `type!:` or a
`BREAKING CHANGE:` footer. Blank line, then a body wrapped at 72 explaining _what_ and _why_,
never _how_. `Co-authored-by:` per human contributor; never AI attribution. One logical change per
commit; propose the split before committing.

Enforced by `.github/workflows/pr-guards.yml` (CI-only, no local mirror yet) — see it for the
exact type/subject checks that block a merge.

## Version Control Discipline

- Don't commit or push on your own initiative — show what changed, get approval, commit only that.
- Commit freely on the working branch; main-line history stays clean (one squashed commit per
  merged change, not its iteration history).
- Rebase onto latest `main` before merging.
- Never rewrite history you don't own. The only sanctioned force-push is your own just-squashed
  branch, and it aborts if the remote moved. If the remote moved unexpectedly, stop and inspect
  before anything destructive — realign, don't overwrite.

## Branch & PR model — short-lived feature branches + protected `main`, rebase-merged

> Concrete realization of **git.md** (Branch & PR model) for this repo, confirmed by the
> `pr-guards.yml` CI signal (single-commit + Conventional-Commit-subject gate).

1. Fetch and check `main` before branching — a stale base means painful divergence later. Branch
   off it per change; the branch is single-use and short-lived.
2. Open the PR as soon as a branch and first commit exist, not after the final squash (`gh pr
create --draft`). Journal decisions, gotchas, decision forks, and retractions as PR comments
   while work proceeds — the PR becomes the real-time record, not a postmortem written at the end.
   `pr-guards.yml` stays quiet on a draft PR and evaluates for real once it's marked ready.
3. Commit freely on the feature branch — WIP commits needn't follow the commit style, since only
   the final squashed commit reaches `main`.
4. One logical change per PR. Never bundle unrelated changes to save a round trip.
5. When ready and tested, squash the branch to exactly one Conventional Commit
   (`git reset --soft origin/main && git commit`), then mark ready for review — the commit reaches
   its final shape here, and `pr-guards.yml` gates on the PR being exactly one commit with a
   Conventional-Commit subject. Rewrite the PR body to stand alone: what changed and why,
   deviations from any prior plan, verification done — a reviewer derives the whole change from a
   one-minute read of the top post, no thread required.
6. Once green, **rebase-merge**: the single commit lands on `main` verbatim, and the branch
   auto-deletes.
7. `main` stays releasable, never committed to directly. Merge method is rebase-merge only,
   enforced by the single-commit + Conventional-Commit checks.

A PR labeled `architecture` must add or modify a `docs/adr/` file — see
[`docs/adr/README.md`](docs/adr/README.md) for when a decision warrants one; `adr-guard.yml`
enforces only the presence, not the judgment call.

## Working iteratively when you can't self-verify

Open-PR-early (step 2 above) still applies regardless of how verifiable the change is: always
open via `gh pr create --draft`, never the plain path, even when the change is already done and
verified. Draft means the agent is still working, ready-for-review means it's the human's turn —
squash to one commit and mark ready at that handoff for all work, verifiable or not. For changes
that can't be confirmed alone (GUI, TUI, rendering, keybindings), the human's confirmation folds
into reviewing the ready PR rather than gating the flip to ready. Staying in draft at handoff is
the exception, not the default: only when the agent specifically needs the human to test something
_before_ code review can happen, and it says so in the handoff message.

## Shift-left tooling and credential scope

> Concrete realization of **git.md** (Shift-left tooling) and **github.md** (Local tooling,
> Credentials) for this repo.

- `just lint` (wraps `lefthook run pre-commit --all-files`) mirrors what CI's `lint` job runs —
  run it before pushing. `just adr "<title>"` stamps a numbered ADR from the template. `just
format` fixes what `lefthook`'s `md-format` job only checks (deliberately a recipe, not a hook).
- `gh` should run under a scoped-down token (contents/PRs/actions read-write, no Administration)
  for routine work — see `.envrc.local.example` for the credential pattern (`GH_TOKEN` aliased to
  `GITHUB_TOKEN`). Elevate explicitly (`env -u GH_TOKEN -u GITHUB_TOKEN gh ...`) only for the one
  action that needs admin scope (branch protection, labels).
- `act` runs the Actions workflows locally via Docker, for testing without pushing.

## Releases

Not wired up — `include_release_automation=false` at scaffold time (#3): this repo is consumed as
a submodule tracking `main`, no SemVer releases yet. Flip that copier answer later (see
`project-starter-template`'s `git-flow` template) if versioned releases are ever wanted.

## Structure & conventions

<!-- TODO: once claude/{rules,agents,skills} content lands, document the directory layout and
naming conventions here. Currently just the git-flow governance scaffold: .github/, docs/adr/,
scripts/, lefthook/justfile composition. -->
