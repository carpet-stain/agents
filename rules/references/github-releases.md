<!-- GitHub release and changelog mechanics. Canonical source: this repo. Relocated verbatim
     from platform/github.md (#49): rare-path content in the read-on-demand references tier —
     see README.md's loading model for the tier's contract. -->

> ### GATE
>
> Applies only if this repo's origin is GitHub (remote points at github.com, or gh is configured
> for it) AND release or changelog work is at hand. Wrong for non-GitHub repos — don't apply
> these mechanics there. Never loaded ambiently; a pointer in `platform/github.md` names it.

# GitHub Releases and Changelog

## Releases — gh

Publish notes from the same git-cliff source as `rules/references/git-releases.md` (resolved
beside this file):
`gh release create <TAG> --notes-file <(git cliff --tag <TAG> --latest --strip all)`.

## Changelog PR links — git-cliff GitHub remote

Realizes `rules/references/git-releases.md`'s "resolve PR links via the host's API" principle on
GitHub: `cliff.toml`'s `[git]` section sets `commit_preprocessors` to strip any legacy "(#N)"
text instead of linking it, and a `[remote.github]` section (`owner`, `repo`) plus a template
using `commit.remote.pr_number` resolve the link at generation time. Never put a token in
`[remote.github]`'s `token` field — pass it via the `GITHUB_TOKEN` env var (or `--github-token`)
at invocation time instead, same as any other secret. `git-cliff` specifically wants
`GITHUB_TOKEN`, not `gh`'s `GH_TOKEN` — alias it to whatever scoped token this repo's credential
setup already provides (`git.md`'s credential-scoping principle) rather than introducing a
second one. In CI, wire `GITHUB_TOKEN` (the default token, or the release credential already in
scope) into every workflow step that invokes `git cliff`. Unauthenticated GitHub API is
60 req/hr — a token raises that to a workable ceiling for a full-history regeneration.
