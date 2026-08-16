#!/usr/bin/env bash
# Architecture boundary checker with debt ratchet.
# Rules:    .grok/arch/boundaries.txt   lines:  deny <path-glob> -> <regex>
# Baseline: .grok/arch/arch-baseline.txt (legacy debt fingerprints, committed)
#
# Usage:
#   bash .grok/scripts/arch-check.sh [root]                  # gate: NEW violations fail
#   bash .grok/scripts/arch-check.sh [root] --baseline-write # record current debt as legacy
#
# Ratchet semantics: baselined (legacy) violations are tolerated and counted;
# violations not in the baseline are new debt and fail the gate. Paying off
# debt? Re-run --baseline-write to shrink the baseline.
# Exit 0 = clean or legacy-only. Exit 1 = new violations.
set -u

ROOT="."
MODE="check"
for a in "$@"; do
  case "$a" in
    --baseline-write) MODE="baseline" ;;
    *) ROOT=$a ;;
  esac
done
cd "$ROOT" || { echo "arch-check: bad root: $ROOT" >&2; exit 1; }
RULES=".grok/arch/boundaries.txt"
BASELINE=".grok/arch/arch-baseline.txt"

if [ ! -f "$RULES" ]; then
  echo "arch-check: no $RULES; nothing to enforce (green)"
  exit 0
fi
if ! command -v rg >/dev/null 2>&1; then
  echo "arch-check: ripgrep (rg) required but not found; cannot enforce" >&2
  exit 0
fi

CURRENT=$(mktemp) || exit 1
trap 'rm -f "$CURRENT"' EXIT

LINENO_=0
while IFS= read -r line || [ -n "$line" ]; do
  LINENO_=$((LINENO_ + 1))
  case "$line" in
    ''|\#*) continue ;;
  esac
  case "$line" in
    deny\ *) ;;
    *) echo "arch-check: $RULES:$LINENO_: unrecognized rule (expected: deny <glob> -> <regex>)" >&2; continue ;;
  esac
  body=${line#deny }
  scope=${body%% -\> *}
  pattern=${body#* -\> }
  if [ "$scope" = "$body" ] || [ -z "$scope" ] || [ -z "$pattern" ]; then
    echo "arch-check: $RULES:$LINENO_: malformed rule" >&2
    continue
  fi
  # Fingerprint = rule + offending file (no line numbers: stable across edits).
  rg -l --glob "$scope" -e "$pattern" . 2>/dev/null \
    | grep -v '^\./\.grok/' \
    | while IFS= read -r f; do
        printf 'deny %s -> %s | %s\n' "$scope" "$pattern" "$f"
      done >>"$CURRENT"
done <"$RULES"

sort -u -o "$CURRENT" "$CURRENT"

if [ "$MODE" = "baseline" ]; then
  mkdir -p "$(dirname "$BASELINE")"
  {
    echo "# arch-check debt baseline (legacy violations tolerated by the ratchet)"
    echo "# regenerate after paying off debt: bash .grok/scripts/arch-check.sh --baseline-write"
    cat "$CURRENT"
  } >"$BASELINE"
  n=$(grep -vc '^#' "$BASELINE" || true)
  echo "arch-check: baseline written ($n legacy violation(s)) -> $BASELINE"
  exit 0
fi

if [ -s "$CURRENT" ]; then
  if [ -f "$BASELINE" ]; then
    KNOWN=$(mktemp) || exit 1
    grep -v '^#' "$BASELINE" 2>/dev/null | sort -u >"$KNOWN"
    NEW=$(comm -23 "$CURRENT" "$KNOWN")
    LEGACY_COUNT=$(comm -12 "$CURRENT" "$KNOWN" | wc -l | tr -d ' ')
    PAID_COUNT=$(comm -13 "$CURRENT" "$KNOWN" | wc -l | tr -d ' ')
    rm -f "$KNOWN"
    [ "$PAID_COUNT" -gt 0 ] && echo "arch-check: $PAID_COUNT baselined violation(s) no longer present; consider --baseline-write to shrink the baseline"
    if [ -n "$NEW" ]; then
      echo "NEW violations (not in baseline -- zero tolerance):"
      printf '%s\n' "$NEW" | while IFS= read -r v; do
        f=${v##*| }
        pat=${v#* -> }; pat=${pat%% | *}
        echo "  $v"
        rg -n -e "$pat" "$f" 2>/dev/null | head -3 | sed 's/^/    /'
      done
      echo "arch-check: FAIL ($LEGACY_COUNT legacy tolerated, new debt above)"
      exit 1
    fi
    echo "arch-check: PASS ($LEGACY_COUNT legacy violation(s) tolerated by baseline)"
    exit 0
  fi
  echo "Violations (no baseline -- all treated as new):"
  while IFS= read -r v; do
    f=${v##*| }
    pat=${v#* -> }; pat=${pat%% | *}
    echo "  $v"
    rg -n -e "$pat" "$f" 2>/dev/null | head -3 | sed 's/^/    /'
  done <"$CURRENT"
  echo "arch-check: FAIL (brownfield adoption: record legacy debt via --baseline-write, then keep new debt at zero)"
  exit 1
fi

echo "arch-check: PASS"
exit 0
