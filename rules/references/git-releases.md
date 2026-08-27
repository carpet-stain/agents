<!-- Release mechanics, platform-agnostic. Canonical source: this repo. Relocated verbatim
     from tools/git.md (#49): rare-path content in the read-on-demand references tier — see
     README.md's loading model for the tier's contract. -->

> ### GATE
>
> Applies only if this repo uses git AND versions releases. Read at release time — this file is
> never loaded ambiently; a pointer in `tools/git.md` names it.

# Releases — git-cliff

Cut <version-scheme> from Conventional Commits: on a release branch `git cliff --tag <TAG> -o
CHANGELOG.md`, commit as `chore(release): <TAG>`, PR, rebase-merge, then `git tag -a <TAG> -m <TAG>
&& git push origin <TAG>`. Publishing notes is host-specific — see the platform reference
(`rules/references/github-releases.md` for GitHub, resolved beside this file).

Resolve PR/MR changelog links via the host's API at changelog-generation time, not by encoding
them into the commit message: rebase-merge (or any strategy that preserves the author's SHA)
means a pre-merge text convention can't survive history rewrites the host itself doesn't do, but
the host tracks the commit↔PR association server-side regardless of merge strategy, so a
generation-time lookup is the durable source, not the commit text. Host-specific config lives in
the platform reference.
