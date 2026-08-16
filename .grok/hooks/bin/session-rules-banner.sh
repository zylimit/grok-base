#!/usr/bin/env bash
# SessionStart banner (Unix)
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh" 2>/dev/null || true

if command -v fast_mode_active >/dev/null 2>&1 && fast_mode_active 2>/dev/null; then
  printf '%s\n' '!! FAST-MODE ON: quality gates muted. Run: bash .grok/scripts/fast-mode.sh off !!'
  exit 0
fi

cat <<'EOF'
========================================================
 Grok Base Core Rules
========================================================
 1. Main agent does not write business code directly
 2. Fresh subagent each task; no nested spawn
 3. Accept on fresh evidence
 4. Preserve framework assets (user approval to delete)
 5. Three-file sync when Spec/progress exist
 6. User scope wins; safety never skips
========================================================
EOF
exit 0
