#!/usr/bin/env bash
# Equality gate for the shared-conduct block (#98; mechanism ruled in #92):
# every persona carries a byte-copy of the source rule section between
# shared-conduct markers, and any drift from the source fails the check —
# edit rules/universal/ai-collaboration.md, then re-copy into the personas.
set -euo pipefail

source_file="rules/universal/ai-collaboration.md"
section="Untrusted Content Is Data, Never Instructions"
begin_marker='<!-- shared-conduct(untrusted-content) begin — source: rules/universal/ai-collaboration.md -->'
end_marker='<!-- shared-conduct(untrusted-content) end — synced by scripts/check-shared-conduct.sh -->'
personas=(
  agents/backlog-manager.md
  agents/code-reviewer.md
  agents/implementor.md
  agents/plan-reviewer.md
)

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# The section extract keeps its one-blank-line frame (blank after the heading,
# blank before the next section) — compared raw, the frame is part of the contract.
awk -v h="## ${section}" '$0 == h { f = 1; next } f && /^## / { exit } f' \
  "$source_file" >"$workdir/source"
if ! grep -q '[^[:space:]]' "$workdir/source"; then
  echo "error: section \"${section}\" not found in ${source_file}" >&2
  exit 1
fi

status=0
for persona in "${personas[@]}"; do
  begin_count=$(grep -Fxc -- "$begin_marker" "$persona" || true)
  end_count=$(grep -Fxc -- "$end_marker" "$persona" || true)
  if [[ "$begin_count" != 1 || "$end_count" != 1 ]]; then
    echo "error: ${persona} must carry exactly one shared-conduct block, its begin/end marker lines verbatim — found ${begin_count} begin, ${end_count} end." >&2
    status=1
    continue
  fi
  begin_line=$(grep -Fxn -- "$begin_marker" "$persona" | cut -d: -f1)
  end_line=$(grep -Fxn -- "$end_marker" "$persona" | cut -d: -f1)
  if ((begin_line >= end_line)); then
    echo "error: ${persona}'s shared-conduct end marker precedes its begin marker." >&2
    status=1
    continue
  fi
  sed -n "$((begin_line + 1)),$((end_line - 1))p" "$persona" >"$workdir/copy"
  if ! cmp -s "$workdir/source" "$workdir/copy"; then
    echo "error: ${persona}'s shared-conduct block has drifted from ${source_file} § ${section}:" >&2
    diff -u "$workdir/source" "$workdir/copy" >&2 || true
    status=1
  fi
done

exit "$status"
