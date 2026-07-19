#!/usr/bin/env bash
# gen-manifest.sh - regenerate .grok/FRAMEWORK-MANIFEST.txt
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SRC="$ROOT/.grok"
OUT="$SRC/FRAMEWORK-MANIFEST.txt"
[ -d "$SRC" ] || { echo "missing .grok: $SRC" >&2; exit 1; }

norm_sha() { tr -d '\r' <"$1" | sha256sum | awk '{print $1}'; }

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

while IFS= read -r -d '' src; do
  rel=${src#"$SRC"/}
  case "$rel" in
    FRAMEWORK-MANIFEST.txt|hooks/project-hooks.json) continue ;;
    settings.local.json|config.local.toml) continue ;;
    .needs-review|.needs-review.lock|.fast-mode|.stop-reminder|.feedback-signal) continue ;;
    signals.jsonl|*/signals.jsonl) continue ;;
    evidence/*) continue ;;
    *.bak|*.framework-new) continue ;;
    feedback/templates/*) ;;
    feedback/*/*) ;;
    feedback/*.md) continue ;;
  esac
  printf '%s\t%s\n' "$rel" "$(norm_sha "$src")"
done < <(find "$SRC" -type f -print0) | sort >"$TMP"

if [ -f "$ROOT/AGENTS.md" ]; then
  printf '../AGENTS.md\t%s\n' "$(norm_sha "$ROOT/AGENTS.md")" >>"$TMP"
  sort -o "$TMP" "$TMP"
fi

{
  echo '# grok-base FRAMEWORK-MANIFEST'
  echo '# format: <path-relative-to-.grok><TAB><sha256-LF-normalized>'
  echo '# regenerate: bash .grok/scripts/gen-manifest.sh'
  cat "$TMP"
} >"$OUT"

echo "wrote $OUT ($(wc -l <"$TMP" | tr -d ' ') files)"
