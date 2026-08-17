#!/bin/bash
# PostToolUse (edit tools): register business files for later review.
# Passive Mode makes this a no-op.
# .needs-review lines: relpath<TAB>fingerprint  (old: relpath only = no fingerprint)
# A lone "clean" line still means reviewed-clear.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

ROOT=$(project_root) || exit 0
fast_mode_active && exit 0

read_stdin
PATHS=$(tool_file_paths)
[ -n "$PATHS" ] || exit 0

STATE="$ROOT/.grok/.needs-review"
register() {
  local file_path=$1 rel fp tmp
  case "$file_path" in
    /*|[A-Za-z]:*) ;;
    *) file_path="$ROOT/$file_path" ;;
  esac
  rel=${file_path#"$ROOT"/}
  rel=${rel#./}
  case "$rel" in
    .grok/*|docs/*|tools/*) return 0 ;;
    *.md|*.txt|*.json|*.yaml|*.yml|*.toml|*.lock|*.log|*.gitignore) return 0 ;;
  esac
  [ -f "$file_path" ] || return 0
  fp=$(file_fingerprint "$ROOT" "$file_path") || fp=""
  if [ -z "$fp" ]; then
    printf 'mark-review: cannot fingerprint %s\n' "$rel" >&2
    return 0
  fi
  tmp="${STATE}.tmp.$$"
  if [ -f "$STATE" ]; then
    awk -F '\t' -v p="$rel" '$0=="clean"{next} $1!=p{print}' "$STATE" > "$tmp" || true
    mv -- "$tmp" "$STATE"
  fi
  printf '%s\t%s\n' "$rel" "$fp" >> "$STATE"
}

if [ ! -f "$STATE" ] || grep -qx "clean" "$STATE" 2>/dev/null; then
  : > "$STATE"
fi

while IFS= read -r p; do
  [ -n "$p" ] && register "$p"
done <<EOF
$PATHS
EOF

exit 0
