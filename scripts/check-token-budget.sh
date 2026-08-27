#!/usr/bin/env bash
# Ratchets the always-loaded rules/ token total against a committed baseline
# (agents#34): no arbitrary ceiling to retune, growth is a reviewable diff —
# raise rules/token-budget-baseline explicitly, or trim something to pay for
# it. Counting is chars/4, a rough estimate not a real tokenizer
# (dotfiles#436) — the trend/delta matter, not precision; don't "fix" this
# into a dependency. `paths:`-gated files (rules/tools/go.md and friends)
# don't count: Claude Code skips loading them in a repo with no matching
# files (claude/README.md's loading table in dotfiles), so they're not part
# of the permanent tax. rules/references/ doesn't count either — the
# read-on-demand tier never loads ambiently (README.md's loading model, #49);
# it gets its own report line for visibility, no cap until growth appears.
set -uo pipefail

baseline_file="rules/token-budget-baseline"

has_paths_gate() {
  [[ "$(sed -n '1p' "$1" 2>/dev/null)" == "---" ]] || return 1
  sed -n '2,/^---$/p' "$1" | grep -q '^paths:'
}

is_always_loaded() {
  case "$1" in
    rules/references/*) return 1 ;;
    rules/*/*.md)
      has_paths_gate "$1" && return 1
      return 0
      ;;
    *) return 1 ;;
  esac
}

tokens_of() {
  [[ -f "$1" ]] || {
    echo 0
    return
  }
  local chars
  chars=$(wc -c <"$1" | tr -d ' ')
  echo $(((chars + 3) / 4))
}

tokens_at_head() {
  local chars
  chars=$(git show "HEAD:$1" 2>/dev/null | wc -c | tr -d ' ')
  echo $(((${chars:-0} + 3) / 4))
}

fmt_k() {
  awk -v n="$1" 'BEGIN { printf "%.1fk", n / 1000 }'
}

always_loaded_files() {
  find rules -name '*.md' | while IFS= read -r f; do
    is_always_loaded "$f" && echo "$f"
  done
}

baseline=$(cat "$baseline_file" 2>/dev/null || echo 0)

total=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  total=$((total + $(tokens_of "$f")))
done < <(always_loaded_files)

for arg in "$@"; do
  is_always_loaded "$arg" || continue
  after=$(tokens_of "$arg")
  before=$(tokens_at_head "$arg")
  printf 'token-budget: %s %s tokens (%+d this commit)\n' "$arg" "$(fmt_k "$after")" "$((after - before))"
done

ref_total=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  ref_total=$((ref_total + $(tokens_of "$f")))
done < <(find rules/references -name '*.md' 2>/dev/null)

printf 'token-budget: always-loaded rules/ total %s / %s baseline\n' "$(fmt_k "$total")" "$(fmt_k "$baseline")"
printf 'token-budget: references/ (read-on-demand) total %s\n' "$(fmt_k "$ref_total")"

if [[ "$total" -gt "$baseline" ]]; then
  echo "error: always-loaded rules/ total ($total tokens) exceeds the committed baseline ($baseline, $baseline_file) — trim a rule, or raise the baseline explicitly if the growth is justified." >&2
  exit 1
fi

exit 0
