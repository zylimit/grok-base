#!/usr/bin/env bash
# ADR enforcement wiring check.
# Usage: bash .grok/scripts/adr-check.sh [root]
# Scans docs/adr/*.md. No dir -> "nothing to check", exit 0.
# Active (Accepted/Proposed) ADRs must have Enforced-by: with a resolvable token.
# `manual` alone does not count. Ghost check names fail.
set -u

ROOT=${1:-.}
cd "$ROOT" || { echo "adr-check: bad root: $ROOT" >&2; exit 1; }

DIR="docs/adr"
if [ ! -d "$DIR" ]; then
  echo "adr-check: nothing to check"
  exit 0
fi

shopt -s nullglob
FILES=("$DIR"/*.md)
shopt -u nullglob
if [ "${#FILES[@]}" -eq 0 ]; then
  echo "adr-check: nothing to check"
  exit 0
fi

FAIL=0
CHECKED=0

strip_md() {
  printf '%s' "$1" | sed 's/\*\*//g;s/`//g;s/\[//g;s/\]//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

adr_field() {
  local file=$1
  local labels=$2
  local line val
  line=$(grep -iE "^[[:space:]]*[-*]?[[:space:]]*(\*\*)?(${labels})(\*\*)?[[:space:]]*[:：]" "$file" 2>/dev/null | head -1 || true)
  [ -n "$line" ] || { printf ''; return 0; }
  val=${line#*[:：]}
  strip_md "$val"
}

is_retired() {
  printf '%s' "$1" | grep -Eiq 'superseded|deprecated|rejected|retired|已废弃|废弃|已取代|已否决|已替代'
}

is_active() {
  local s=$1
  [ -z "$s" ] && return 0
  is_retired "$s" && return 1
  printf '%s' "$s" | grep -Eiq 'accepted|proposed|接受|已接受|提议|草案' && return 0
  return 0
}

is_manual() {
  printf '%s' "$1" | grep -Eiq '^(manual|review|人工|评审|人工评审)$'
}

# 0=machine  1=manual  2=ghost  3=prose/ignore
classify() {
  local raw=$1
  local t lower name
  t=$(strip_md "$raw")
  [ -n "$t" ] || { printf 'ghost'; return 0; }
  lower=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')

  if printf '%s' "$lower" | grep -Eq '(^|[^a-z])(fitness\.sh|fitness)([^a-z]|$)'; then
    printf 'machine'; return 0
  fi
  if printf '%s' "$lower" | grep -Eq '(^|[^a-z])(arch-check|boundaries)([^a-z]|$)'; then
    if [ -f .grok/arch/boundaries.txt ]; then
      printf 'machine'; return 0
    fi
    printf 'ghost'; return 0
  fi

  if [ -e "$t" ] || [ -e "$lower" ]; then
    printf 'machine'; return 0
  fi

  name=$t
  name=${name%.ps1}
  name=${name%.sh}
  name=${name##*/}
  if [ -f ".grok/scripts/${name}.sh" ]; then
    printf 'machine'; return 0
  fi

  if is_manual "$t"; then
    printf 'manual'; return 0
  fi

  # identifier-like: named a check that does not exist
  if printf '%s' "$t" | grep -Eq '^[A-Za-z0-9._/-]+$'; then
    printf 'ghost'; return 0
  fi
  printf 'prose'
}

echo "adr-check: scanning ${#FILES[@]} ADR file(s)"

for f in "${FILES[@]}"; do
  status=$(adr_field "$f" '状态|Status')
  if ! is_active "$status"; then
    echo "  skip (retired): $f  status=${status:-?}"
    continue
  fi
  CHECKED=$((CHECKED + 1))
  enforced=$(adr_field "$f" 'Enforced-by|Enforced by|执法方式')
  if [ -z "$enforced" ]; then
    echo "  FAIL $f: missing Enforced-by"
    FAIL=$((FAIL + 1))
    continue
  fi

  # split on comma / enumeration marks / semicolon (not slash: test paths keep '/')
  tokens=$(printf '%s' "$enforced" | sed 's/[，、；;,]/\n/g')
  machine=0
  manual=0
  ghost=0
  ghosts=""
  while IFS= read -r tok || [ -n "${tok:-}" ]; do
    tok=$(strip_md "$tok")
    [ -n "$tok" ] || continue
    kind=$(classify "$tok")
    case "$kind" in
      machine) machine=$((machine + 1)) ;;
      manual) manual=$((manual + 1)) ;;
      ghost) ghost=$((ghost + 1)); ghosts="${ghosts}${tok};" ;;
      *) ;;
    esac
  done <<EOF
$tokens
EOF

  if [ "$ghost" -gt 0 ]; then
    echo "  FAIL $f: ghost Enforced-by token(s): ${ghosts%;}  (raw: $enforced)"
    FAIL=$((FAIL + 1))
    continue
  fi
  if [ "$machine" -eq 0 ]; then
    echo "  FAIL $f: Enforced-by has no resolvable machine token (manual-only/empty does not count): $enforced"
    FAIL=$((FAIL + 1))
    continue
  fi
  echo "  ok $f  enforced=$enforced"
done

if [ "$CHECKED" -eq 0 ]; then
  echo "adr-check: nothing to check"
  exit 0
fi

if [ "$FAIL" -gt 0 ]; then
  echo "adr-check: FAIL ($FAIL/$CHECKED active ADR(s))"
  exit 1
fi
echo "adr-check: PASS ($CHECKED active ADR(s))"
exit 0
