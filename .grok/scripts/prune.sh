#!/usr/bin/env bash
# Purge grok-base runtime state only. Never touches skills/rules/hooks/bin/scripts sources.
# Usage: bash .grok/scripts/prune.sh [--dry-run|--apply] [root]
# Default: --dry-run (print path + age). --apply actually deletes.
set -u

DRY=1
ROOT="."
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --apply) DRY=0 ;;
    -h|--help)
      printf 'usage: prune.sh [--dry-run|--apply] [root]\n' >&2
      exit 0
      ;;
    -*)
      printf 'prune: unknown flag %s\n' "$a" >&2
      exit 2
      ;;
    *) ROOT=$a ;;
  esac
done

[ -d "$ROOT" ] || { printf 'prune: bad root: %s\n' "$ROOT" >&2; exit 2; }
ROOT=$(cd -- "$ROOT" && pwd -P) || { printf 'prune: cannot enter %s\n' "$ROOT" >&2; exit 2; }

if [ -d "$ROOT/.grok" ]; then
  GROK="$ROOT/.grok"
else
  GROK="$ROOT"
fi

MAX_AGE=$((14 * 86400))
now=$(date +%s) || { printf 'prune: date failed\n' >&2; exit 1; }

mtime_of() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null
}

# Never delete source trees; only named runtime files.
is_allowed() {
  local f=$1 base dir
  base=$(basename -- "$f")
  dir=$(dirname -- "$f")
  case "$base" in
    .needs-review.corrupt-*|.fast-mode.corrupt-*)
      [ "$dir" = "$GROK" ]
      return
      ;;
    .stop-reminder)
      [ "$dir" = "$GROK" ]
      return
      ;;
    gate-log.tsv)
      [ "$dir" = "$GROK/hooks" ]
      return
      ;;
    *) return 1 ;;
  esac
}

age_label() {
  local sec=$1
  printf '%sd' $((sec / 86400))
}

consider() {
  local f=$1 need_age=$2
  [ -e "$f" ] || return 0
  [ -f "$f" ] || return 0
  is_allowed "$f" || return 0
  local mt age
  mt=$(mtime_of "$f") || return 0
  case "$mt" in ''|*[!0-9]*) return 0 ;; esac
  age=$((now - mt))
  if [ "$need_age" -eq 1 ] && [ "$age" -le "$MAX_AGE" ]; then
    return 0
  fi
  if [ "$DRY" -eq 1 ]; then
    printf 'dry-run: %s  age=%s\n' "$f" "$(age_label "$age")"
  else
    if rm -f -- "$f"; then
      printf 'deleted: %s  age=%s\n' "$f" "$(age_label "$age")"
    else
      printf 'prune: FAIL delete %s\n' "$f" >&2
      return 1
    fi
  fi
  return 0
}

shopt -s nullglob
fail=0
for f in "$GROK"/.needs-review.corrupt-* "$GROK"/.fast-mode.corrupt-*; do
  consider "$f" 1 || fail=1
done
# stop-reminder: only listed/removed with this script; no 14-day wait (tiny flag).
consider "$GROK/.stop-reminder" 0 || fail=1
# gate-log: mtime older than 14 days only.
consider "$GROK/hooks/gate-log.tsv" 1 || fail=1
shopt -u nullglob

if [ "$DRY" -eq 1 ]; then
  printf 'prune: dry-run (pass --apply to delete)\n'
else
  printf 'prune: apply done\n'
fi
[ "$fail" -eq 0 ] || exit 1
exit 0
