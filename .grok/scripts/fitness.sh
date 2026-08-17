#!/usr/bin/env bash
# Five-attribute anti-pattern scan (secret / pii-log / swallow-error / retry / TODO).
# Usage: bash .grok/scripts/fitness.sh [root] [--allow-empty]
# Output: rule<TAB>file:line<TAB>snippet   then counts. Exit 1 if any finding.
# --allow-empty: zero files after filters -> exit 0 (default: exit 1).
set -u

ROOT="."
ALLOW_EMPTY=0
for a in "$@"; do
  case "$a" in
    --allow-empty) ALLOW_EMPTY=1 ;;
    *) ROOT=$a ;;
  esac
done
cd "$ROOT" || { echo "fitness: bad root: $ROOT" >&2; exit 1; }

C_SECRET=0
C_PII=0
C_SWALLOW=0
C_RETRY=0
C_TODO=0
FINDINGS=0
SCANNED=0

skip_path() {
  local f=$1
  case "$f" in
    .grok/*|.git/*|node_modules/*|.venv/*|venv/*|dist/*|target/*|__pycache__/*) return 0 ;;
    */.grok/*|*/.git/*|*/node_modules/*|*/.venv/*|*/venv/*|*/dist/*|*/target/*|*/__pycache__/*) return 0 ;;
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.pdf|*.zip|*.gz|*.tgz|*.woff|*.woff2|*.ttf|*.eot|*.bin|*.exe|*.dll|*.so|*.dylib|*.o|*.a|*.class|*.jar|*.pyc|*.pyo|*.wasm|*.mp3|*.mp4|*.mov|*.lock) return 0 ;;
    .env.example|.env.sample|.env.template|.env.dist|*.example) return 0 ;;
    */.env.example|*/.env.sample|*/.env.template|*/.env.dist) return 0 ;;
  esac
  return 1
}

RAW=$(mktemp) || exit 1
LIST=$(mktemp) || exit 1
trap 'rm -f "$RAW" "$LIST"' EXIT

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files >"$RAW" 2>/dev/null || true
else
  find . -type f \
    ! -path './.git/*' ! -path './node_modules/*' \
    ! -path './.venv/*' ! -path './venv/*' ! -path './dist/*' \
    | sed 's|^\./||' >"$RAW"
fi

while IFS= read -r f || [ -n "${f:-}" ]; do
  [ -n "${f:-}" ] || continue
  skip_path "$f" && continue
  [ -f "$f" ] || continue
  sz=$(wc -c <"$f" 2>/dev/null | tr -d ' ')
  case "${sz:-0}" in ''|*[!0-9]*) continue ;; esac
  [ "$sz" -gt 1000000 ] && continue
  printf '%s\n' "$f" >>"$LIST"
  SCANNED=$((SCANNED + 1))
done <"$RAW"

if [ ! -s "$LIST" ]; then
  echo "fitness: no files to scan"
  echo "counts: secret-literal=0 pii-log=0 swallow-error=0 unbounded-retry=0 hanging-todo=0"
  if [ "$ALLOW_EMPTY" -eq 1 ]; then
    echo "fitness: PASS (empty, --allow-empty)"
    exit 0
  fi
  echo "fitness: FAIL (empty; pass --allow-empty to allow)"
  exit 1
fi

emit() {
  local rule=$1 loc=$2 snippet=$3
  snippet=$(printf '%s' "$snippet" | tr '\t\r' '  ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -c1-160)
  printf '%s\t%s\t%s\n' "$rule" "$loc" "$snippet"
  FINDINGS=$((FINDINGS + 1))
  case "$rule" in
    secret-literal) C_SECRET=$((C_SECRET + 1)) ;;
    pii-log) C_PII=$((C_PII + 1)) ;;
    swallow-error) C_SWALLOW=$((C_SWALLOW + 1)) ;;
    unbounded-retry) C_RETRY=$((C_RETRY + 1)) ;;
    hanging-todo) C_TODO=$((C_TODO + 1)) ;;
  esac
}

# file:line:snippet  (path colons are rare; first two fields are path + line)
parse_hit() {
  _raw=$1
  _file=${_raw%%:*}
  _rest=${_raw#*:}
  _line=${_rest%%:*}
  _snip=${_rest#*:}
}

search() {
  local pat=$1
  if [ ! -s "$LIST" ]; then return 0; fi
  if command -v rg >/dev/null 2>&1; then
    rg -n --no-heading -e "$pat" --files-from "$LIST" 2>/dev/null || true
  else
    tr '\n' '\0' <"$LIST" | xargs -0 grep -n -E -H -e "$pat" -- 2>/dev/null || true
  fi
}

line_at() {
  local file=$1 n=$2
  [ "$n" -ge 1 ] || { printf ''; return 0; }
  sed -n "${n}p" "$file" 2>/dev/null || true
}

has_ticket() {
  local a=$1 b=$2 c=$3
  printf '%s\n%s\n%s\n' "$a" "$b" "$c" | grep -Eqi '(^|[^A-Za-z])(issue|ticket)([^A-Za-z]|$)|#[0-9]+'
}

is_placeholder_value() {
  local v=$1
  printf '%s' "$v" | grep -Eiq '^(your[-_].*|x+|placeholder.*|change.?me|redacted|dummy|example|insert[-_].*|<[^>]+>|\$\{[^}]+\})$'
}

is_md() {
  case "$1" in *.md|*.mdx|*.markdown) return 0 ;; esac
  return 1
}

# --- secret-literal ---
while IFS= read -r hit || [ -n "${hit:-}" ]; do
  [ -n "${hit:-}" ] || continue
  parse_hit "$hit"
  case "${_line:-}" in ''|*[!0-9]*) continue ;; esac
  if is_md "$_file"; then
    printf '%s' "$_snip" | grep -Eq 'password[[:space:]]*=[[:space:]]*['\''"]|token[[:space:]]*=[[:space:]]*['\''"]' \
      && printf '%s' "$_snip" | grep -Eqv 'AKIA[0-9A-Z]{16}|BEGIN[[:space:]]+[A-Z0-9 ]*PRIVATE[[:space:]]+KEY' \
      && continue
  fi
  val=$(printf '%s' "$_snip" | sed -n 's/.*['\''"]\([^'\''"]*\)['\''"].*/\1/p' | head -1)
  if [ -n "$val" ] && is_placeholder_value "$val"; then
    continue
  fi
  emit secret-literal "${_file}:${_line}" "$_snip"
done <<EOF
$(search 'AKIA[0-9A-Z]{16}|-----BEGIN[ A-Z0-9]*PRIVATE KEY-----|(^|[^A-Za-z0-9_])sk-[A-Za-z0-9_-]{16,}|(password|passwd|api[_-]?key|secret|token)[[:space:]]*=[[:space:]]*['\''"][^'\''"]+['\''"]')
EOF

# --- pii-log ---
while IFS= read -r hit || [ -n "${hit:-}" ]; do
  [ -n "${hit:-}" ] || continue
  parse_hit "$hit"
  case "${_line:-}" in ''|*[!0-9]*) continue ;; esac
  emit pii-log "${_file}:${_line}" "$_snip"
done <<EOF
$(search '(console\.(log|info|warn|debug|error)|logger\.(log|info|warn|debug|error|fine)|log\.(info|warn|debug|error|fine)|printf?|println|fmt\.Print[a-zA-Z]*)[[:space:]]*\([^)\n]*(email|phone|id_card|password|token)')
EOF

# --- swallow-error ---
while IFS= read -r hit || [ -n "${hit:-}" ]; do
  [ -n "${hit:-}" ] || continue
  parse_hit "$hit"
  case "${_line:-}" in ''|*[!0-9]*) continue ;; esac
  prev=$(line_at "$_file" $((_line - 1)))
  # comment on this or previous line documents the swallow
  if printf '%s\n%s\n' "$prev" "$_snip" | grep -Eq '(#|//|/\*)[[:space:]]*(fail-open|intentional|ignore|n\/a|ok|expected)'; then
    continue
  fi
  if printf '%s' "$_snip" | grep -Eq '(#|//).*(catch|except|pass)'; then
    continue
  fi
  emit swallow-error "${_file}:${_line}" "$_snip"
done <<EOF
$(search 'catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*\}|except[^:\n]*:[[:space:]]*(pass|\.\.\.)[[:space:]]*($|#)')
EOF

# two-line empty catch { / }
while IFS= read -r f || [ -n "${f:-}" ]; do
  [ -n "${f:-}" ] || continue
  [ -f "$f" ] || continue
  ln=0
  prev=""
  while IFS= read -r line || [ -n "${line:-}" ]; do
    ln=$((ln + 1))
    if printf '%s' "$prev" | grep -Eq 'catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*$' \
      && printf '%s' "$line" | grep -Eq '^[[:space:]]*\}[[:space:]]*($|#|//)'; then
      if ! printf '%s\n%s\n' "$prev" "$line" | grep -Eq '(#|//|/\*)[[:space:]]*(fail-open|intentional|ignore)'; then
        emit swallow-error "${f}:${ln}" "$prev / $line"
      fi
    fi
    prev=$line
  done <"$f"
done <"$LIST"

# --- unbounded-retry (conservative: while-true + retry nearby, no bound) ---
while IFS= read -r f || [ -n "${f:-}" ]; do
  [ -n "${f:-}" ] || continue
  [ -f "$f" ] || continue
  ln=0
  while IFS= read -r line || [ -n "${line:-}" ]; do
    ln=$((ln + 1))
    printf '%s' "$line" | grep -Eqi 'while[[:space:]]*\([[:space:]]*true[[:space:]]*\)|while[[:space:]]+True[[:space:]]*:|while[[:space:]]+true([[:space:]]*;|[[:space:]]+do|[[:space:]]*$)' \
      || continue
    start=$ln
    end=$((ln + 24))
    win=$(sed -n "${start},${end}p" "$f" 2>/dev/null || true)
    printf '%s' "$win" | grep -Eqi '\bretry|\bretries|\breconnect\b' || continue
    if printf '%s' "$win" | grep -Eqi 'max[_-]?retr|max[_-]?attempt|attempt[s]?[[:space:]]*[<>=]|retry_count|retries[[:space:]]*[<>=]|for[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in[[:space:]]+range\(|break[[:space:]]+after'; then
      continue
    fi
    emit unbounded-retry "${f}:${ln}" "$line"
  done <"$f"
done <"$LIST"

# --- hanging-todo ---
while IFS= read -r hit || [ -n "${hit:-}" ]; do
  [ -n "${hit:-}" ] || continue
  parse_hit "$hit"
  case "${_line:-}" in ''|*[!0-9]*) continue ;; esac
  printf '%s' "$_snip" | grep -Eq '^[[:space:]]*#{1,6}[[:space:]]*(TODO|FIXME|XXX)\b' && continue
  # prose mention, not a marker
  printf '%s' "$_snip" | grep -Eq '(#|//|/\*|\*|<!--|--)[[:space:]]*(TODO|FIXME|XXX)\b|^[[:space:]]*(TODO|FIXME|XXX):' \
    || continue
  prev=$(line_at "$_file" $((_line - 1)))
  next=$(line_at "$_file" $((_line + 1)))
  if has_ticket "$prev" "$_snip" "$next"; then
    continue
  fi
  emit hanging-todo "${_file}:${_line}" "$_snip"
done <<EOF
$(search '(TODO|FIXME|XXX)')
EOF

echo "fitness: scanned=${SCANNED} findings=${FINDINGS}"
echo "counts: secret-literal=${C_SECRET} pii-log=${C_PII} swallow-error=${C_SWALLOW} unbounded-retry=${C_RETRY} hanging-todo=${C_TODO}"
if [ "$FINDINGS" -gt 0 ]; then
  echo "fitness: FAIL"
  exit 1
fi
echo "fitness: PASS"
exit 0
