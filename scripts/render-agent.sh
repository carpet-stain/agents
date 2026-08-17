#!/usr/bin/env bash
# Renders the cloud-channel "owned carve-out" for a consumer repo: each named
# agent's persona (skill-closure resolved, cloud-transformed) plus the skills
# it runs, and the .agents-ref pin. See docs/adr/0002 for the channel this
# implements (carpet-stain/dotfiles#597).
#
# usage:
#   render-agent.sh --agents-repo <path> --consumer-dir <path> [--check] [agent ...]
#
# Without --check: writes <consumer-dir>/agents/<name>.md,
# <consumer-dir>/skills/<name>/, and <consumer-dir>/.agents-ref (the
# --agents-repo checkout's HEAD SHA), then exits 0.
#
# With --check: renders into a scratch dir and diffs against what's already
# committed under consumer-dir; no-ops (exit 0) if consumer-dir/.agents-ref
# is absent — a virgin consumer has nothing vendored yet to check. The
# caller is responsible for checking --agents-repo out at the SHA recorded
# in consumer-dir/.agents-ref before invoking --check (issue #597 finding 4:
# the guard compares against the pinned ref, never floating main).
#
# agent names default to the basenames of consumer-dir/agents/*.md already
# present — the hosted set is derived from presence, never a separate
# manifest (issue #597 finding 7).
set -euo pipefail

agents_repo=""
consumer_dir=""
check=0
agent_names=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agents-repo)
      agents_repo="$2"
      shift 2
      ;;
    --consumer-dir)
      consumer_dir="$2"
      shift 2
      ;;
    --check)
      check=1
      shift
      ;;
    *)
      agent_names+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$agents_repo" || -z "$consumer_dir" ]]; then
  echo "usage: $0 --agents-repo <path> --consumer-dir <path> [--check] [agent ...]" >&2
  exit 1
fi

if [[ $check -eq 1 && ! -f "$consumer_dir/.agents-ref" ]]; then
  echo "no .agents-ref in $consumer_dir yet — nothing vendored, skipping check."
  exit 0
fi

if [[ ${#agent_names[@]} -eq 0 ]]; then
  for f in "$consumer_dir"/agents/*.md; do
    [[ -e "$f" ]] || continue
    agent_names+=("$(basename "${f%.md}")")
  done
fi

if [[ ${#agent_names[@]} -eq 0 ]]; then
  echo "no agents to render (none named, none present in $consumer_dir/agents)."
  exit 0
fi

agent_body() {
  awk 'f { print } /^---$/ { c++; if (c == 2) f = 1 }' "$agents_repo/agents/${1}.md"
}

# RUN-instructed skills only, never backstop skills — see ADR-0002.
skill_closure() {
  local persona_body="$1" name
  for skill_dir in "$agents_repo"/skills/*/; do
    [[ -d "$skill_dir" ]] || continue
    name="$(basename "$skill_dir")"
    if grep -E "\`${name}\`[[:space:]]+skill" <<<"$persona_body" | grep -qv "backstop"; then
      echo "$name"
    fi
  done
}

# Strips mcpServers/mcp__memory and rewrites ## Memory — see ADR-0002.
cloud_transform() {
  awk '
    function flush_comments() { for (i = 1; i <= cbuf_n; i++) print cbuf[i]; cbuf_n = 0 }
    BEGIN { state = 0; cbuf_n = 0; in_mcp = 0; in_memory = 0; memory_seen = 0 }
    state == 0 {
      print
      if ($0 == "---") state = 1
      next
    }
    state == 1 {
      if (in_mcp) {
        if ($0 ~ /^[ \t]/ || $0 == "") next
        in_mcp = 0
      }
      if ($0 == "---") { flush_comments(); print; state = 2; next }
      if ($0 ~ /^mcpServers:/) { cbuf_n = 0; in_mcp = 1; next }
      if ($0 ~ /^#/) { cbuf[++cbuf_n] = $0; next }
      flush_comments()
      if ($0 ~ /^tools:/) {
        gsub(/, *mcp__memory/, "")
        gsub(/mcp__memory, */, "")
        gsub(/^tools: *mcp__memory$/, "tools:")
      }
      print
      next
    }
    state == 2 {
      if (!memory_seen && $0 ~ /^## Memory/) {
        print
        print ""
        print "Memory unavailable on this surface — see #602."
        in_memory = 1
        memory_seen = 1
        next
      }
      if (in_memory) {
        if ($0 ~ /^## /) { in_memory = 0 } else { next }
      }
      print
    }
  '
}

render_agent() {
  local name="$1" out_dir="$2" src skill
  src="$agents_repo/agents/${name}.md"
  if [[ ! -f "$src" ]]; then
    echo "error: no such agent in $agents_repo: $name" >&2
    exit 1
  fi

  mkdir -p "$out_dir/agents"
  cloud_transform <"$src" >"$out_dir/agents/${name}.md"

  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    mkdir -p "$out_dir/skills"
    rm -rf "${out_dir:?}/skills/${skill}"
    cp -R "$agents_repo/skills/${skill}" "$out_dir/skills/${skill}"
  done < <(skill_closure "$(agent_body "$name")")
}

sha="$(git -C "$agents_repo" rev-parse HEAD)"

if [[ $check -eq 1 ]]; then
  scratch="$(mktemp -d)"
  trap 'rm -rf "$scratch"' EXIT

  drift=0
  for name in "${agent_names[@]}"; do
    render_agent "$name" "$scratch"
    if ! diff -u "$consumer_dir/agents/${name}.md" "$scratch/agents/${name}.md"; then
      drift=1
    fi
    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      if ! diff -rq "$consumer_dir/skills/${skill}" "$scratch/skills/${skill}" >/dev/null 2>&1; then
        echo "drift: skills/${skill} differs from the renderer's output" >&2
        drift=1
      fi
    done < <(skill_closure "$(agent_body "$name")")
  done

  if [[ $drift -ne 0 ]]; then
    echo "::error::vendored .claude carve-out has drifted from the renderer's output at $sha — re-run the sync workflow." >&2
    exit 1
  fi
  echo "carve-out matches pinned ref $sha — no drift."
  exit 0
fi

for name in "${agent_names[@]}"; do
  render_agent "$name" "$consumer_dir"
done
echo "$sha" >"$consumer_dir/.agents-ref"
