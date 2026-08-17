#!/bin/bash
# Stop is passive in Grok (cannot block). Print / persist a reminder only.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

ROOT=$(project_root) || exit 0
REMINDER="$ROOT/.grok/.stop-reminder"
fast_mode_active && { rm -f "$REMINDER"; exit 0; }

STATE="$ROOT/.grok/.needs-review"
if [ ! -f "$STATE" ]; then
  rm -f "$REMINDER"
  exit 0
fi

FILES=$(grep -vE '^[[:space:]]*$' "$STATE" 2>/dev/null | grep -vx "clean" || true)
if [ -z "$FILES" ]; then
  rm -f "$STATE" "$REMINDER"
  exit 0
fi

{
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    path=${line%%$'\t'*}
    if [ "$path" = "$line" ]; then
      continue
    fi
    fp=${line#*$'\t'}
    [ -n "$fp" ] || continue
    abs="$ROOT/$path"
    [ -f "$abs" ] || continue
    cur=$(file_fingerprint "$ROOT" "$abs") || cur=""
    if [ -n "$cur" ] && [ "$cur" != "$fp" ]; then
      printf 'REVIEW STALE: %s changed since it was marked; re-review.\n' "$path"
    fi
  done <<EOF
$FILES
EOF

  COUNT=$(printf '%s\n' "$FILES" | wc -l | tr -d ' ')
  printf 'STOP REMINDER: %s file(s) pending review. Dispatch code-reviewer, then write clean to .grok/.needs-review.\n' "$COUNT"
} | tee "$REMINDER"
exit 0
