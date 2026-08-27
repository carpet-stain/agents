<!-- GitHub platform mechanics. Canonical source: this repo. Platform-level only: gh CLI,
     GitHub Actions, and GitHub's specific behaviors of the generic git workflow (git.md).
     Wrong for non-GitHub repos. Assumes git.md's workflow is in effect.
     Rationale: README.md. -->

> ### GATE
>
> Applies only if this repo's origin is GitHub (remote points at github.com, or gh is configured
> for it). Otherwise IGNORE this file — don't apply gh/PR mechanics to a GitLab or other repo.

> ### LOCAL-WINS
>
> If this repo has its own GitHub-specific workflow doc, that doc is AUTHORITATIVE: treat this as
> baseline and prefer the repo's doc on conflict.

# GitHub Mechanics

Realizes `git.md`'s workflow on GitHub. No placeholders — `git.md` owns everything composable.

## Rebase-merge and branch protection

GitHub rebase-merge replays the branch's commits onto the protected branch as-is — it doesn't
rewrite the message the way squash-merge does, so the commit itself (already squashed to one,
already a Conventional Commit subject) is what lands, not the PR title. Branch protection
(rules/rulesets) is what enforces `git.md`'s single-commit + rebase-merge rule and required status
checks. "PR" is GitHub's review/merge request.

## Local tooling

Routine `gh` work runs under a scoped-down credential resolved by the repo's own environment
(its `.envrc` or equivalent), never a full-admin session, so an agent driving the CLI can't touch
repo settings or branch protection. Which credential that is, what scopes it carries, and how to
elevate for the one action that needs admin are the repo's own credential doc's to state
(AGENTS.md — LOCAL-WINS): those mechanics vary per repo and drift, so this file keeps only the
principle. One portable rule when elevation works by dropping env vars: drop every variable that
could carry the same token — a repo often aliases `GITHUB_TOKEN` to the same scoped value as
`GH_TOKEN`, so dropping one alone is a no-op. `act` runs the Actions workflows locally via Docker,
for testing without pushing.

## Early draft PRs — `git pr` / `git pr --draft`

Realizes `git.md`'s "open the PR/MR early, journal via comments" principle on GitHub: `git pr
--draft` opens a draft PR as soon as a first commit exists (errors loudly instead of guessing if
one already exists — "did you mean to finalize? run: git pr"); plain `git pr` finalizes an
already-open draft via `gh pr ready`. There's no direct-to-ready path — `git pr` with no draft
open yet errors, telling the operator to run `git pr --draft` first, matching git.md's rule that
the draft step is never skipped, even for already-verified work. Each path asserts its own
precondition — commit count ahead of the base, or draft existence — and fails with a specific
message rather than branching on ambient state. Journal decisions, gotchas, and retractions as
comments on the draft PR as work proceeds.

`pr-guards.yml` (see its own inline comments for the exact gate) stays quiet on WIP pushes to an
early draft and evaluates for real once `git pr` finalizes it — gated per job, not
workflow-level, because a job skipped via a job-level `if:` reads as passing to
required-status-check branch protection, not failing (verified empirically against this repo's
branch protection, not assumed from docs), while a workflow-level `if:` that skips the whole run
is the sharp edge that can hang a required check instead.

## Releases and changelog PR links

GitHub release mechanics (`gh release create` from git-cliff, `cliff.toml`'s remote/token
wiring) live in `rules/references/github-releases.md` — read it when publishing a release or
wiring changelog PR links, and only in a GitHub-origin repo (this file's GATE applies to it
too). Resolve the path against the rules tree, not the current repo: the roster checkout or
vendored copy when working in one, else the deployed
`~/.claude/rules/references/github-releases.md`. Rare-path content, deliberately outside the
ambient load path (#49).
