#!/usr/bin/env bash
# PostToolUse (edit tools): register business files for later review.
# Passive Mode makes this a no-op.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

command -v jq >/dev/null 2>&1 || exit 0
ROOT=$(project_root) || exit 0
fast_mode_active && exit 0

read_stdin
PATHS=$(tool_file_paths)
[ -n "$PATHS" ] || exit 0

STATE="$ROOT/.grok/.needs-review"
register() {
  local file_path=$1 rel
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
  grep -qxF "$rel" "$STATE" 2>/dev/null || printf '%s\n' "$rel" >> "$STATE"
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
