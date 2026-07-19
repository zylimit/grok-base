#!/usr/bin/env bash
# Usage: bash .grok/scripts/fast-mode.sh on [hours] | off | status
set -u
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
FLAG="$ROOT/.grok/.fast-mode"
ACTION=${1:-status}
HOURS=${2:-24}

case "$ACTION" in
  on)
    NOW=$(date +%s)
    EXP=$(( NOW + HOURS * 3600 ))
    printf 'enabled_epoch=%s\nexpires_epoch=%s\nhours=%s\n' "$NOW" "$EXP" "$HOURS" > "$FLAG"
    echo "fast-mode: on (${HOURS}h; quality gates bypassed, safety guards remain active)"
    ;;
  off)
    rm -f "$FLAG"
    echo "fast-mode: off (normal quality workflow restored)"
    ;;
  status)
    if [ -f "$FLAG" ]; then
      EXP=$(sed -n 's/^expires_epoch=//p' "$FLAG" | head -1)
      NOW=$(date +%s)
      if [ -n "$EXP" ] && [ "$EXP" -gt "$NOW" ] 2>/dev/null; then
        LEFT=$(( (EXP - NOW + 59) / 60 ))
        echo "fast-mode: on (about ${LEFT} minutes remaining)"
      else
        echo "fast-mode: expired (normal quality workflow is active; run off to remove stale state)"
      fi
    else
      echo "fast-mode: off"
    fi
    ;;
  *)
    echo "usage: fast-mode.sh on [hours]|off|status" >&2
    exit 1
    ;;
esac
