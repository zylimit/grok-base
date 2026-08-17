#!/bin/bash
# PreCompact: print short keep-pointers. Passive; never block. Always exit 0.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

read_stdin || true
ROOT=$(project_root 2>/dev/null || pwd)

has_progress=no
has_spec=no
[ -f "$ROOT/progress.md" ] && has_progress=yes
[ -f "$ROOT/Product-Spec.md" ] && has_spec=yes

adr_n=0
if [ -d "$ROOT/docs/adr" ]; then
  adr_n=$(find "$ROOT/docs/adr" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
fi

review_n=0
STATE="$ROOT/.grok/.needs-review"
if [ -f "$STATE" ]; then
  review_n=$(grep -vE '^[[:space:]]*$' "$STATE" 2>/dev/null | grep -vx "clean" | wc -l | tr -d ' ')
fi

out=$(printf '%s\n' \
  "PreCompact keep-pointers (not a block):" \
  "- progress.md: ${has_progress}" \
  "- Product-Spec.md: ${has_spec}" \
  "- docs/adr: ${adr_n}" \
  "- .needs-review: ${review_n} line(s)" \
  "Prefer /recap (progress.md + Product-Spec.md + Product-Spec-CHANGELOG.md) after compact.")

# Cap ~2KB
printf '%s\n' "$out" | head -c 2048
echo
exit 0
