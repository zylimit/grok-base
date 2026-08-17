#!/usr/bin/env bash
# Aggregate hook deny counts from gate-log.tsv. Not an auto-unblock engine.
# Usage: bash .grok/scripts/gate-audit.sh [root]
set -u

ROOT=${1:-.}
[ -d "$ROOT" ] || { printf 'gate-audit: bad root: %s\n' "$ROOT" >&2; exit 2; }
cd "$ROOT" || { printf 'gate-audit: cannot enter %s\n' "$ROOT" >&2; exit 2; }

if [ -d .grok ]; then
  LOG=".grok/hooks/gate-log.tsv"
else
  LOG="hooks/gate-log.tsv"
fi

if [ ! -f "$LOG" ]; then
  printf 'gate-audit: no log yet\n'
  exit 0
fi

printf 'hook\tdenies\n'
awk -F '\t' '
  $3 == "deny" {
    h = $2
    if (h == "") h = "unknown"
    c[h]++
    t++
  }
  END {
    for (h in c) print h "\t" c[h]
    print "total\t" (t + 0)
  }
' "$LOG"
exit 0
