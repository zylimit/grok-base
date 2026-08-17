#!/bin/bash
# PreToolUse edit: block main agent writing business source
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

fast_mode_active 2>/dev/null && { allow; exit 0; }
read_stdin

# Sub-agent sessions (implementer etc.) must write business source.
if command -v jq >/dev/null 2>&1; then
  SUBAGENT=$(printf '%s' "${HOOK_JSON:-}" | jq -r '.subagentType // .subagent_type // empty' 2>/dev/null || true)
else
  SUBAGENT=$(printf '%s' "${HOOK_JSON:-}" | sed -n 's/.*"subagentType"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi
[ -n "${SUBAGENT:-}" ] && { allow; exit 0; }

FILE=$(tool_file_paths | head -1)
[ -n "$FILE" ] || { allow; exit 0; }
FP=$(printf '%s' "$FILE" | tr '\\' '/')

case "$FP" in
  *.md|*.json|*.toml|*.cmd|*.ps1|*.sh|.grok/*|*/.grok/*|*AGENTS.md*|*Product-Spec*|*DEV-PLAN*|*progress.md*|*CHANGELOG*|*feedback*|*agents*|*skills*|*hooks*|*roles*|*personas*)
    allow; exit 0 ;;
esac

case "$FP" in
  */src/*|*/app/*|*/lib/*|*/components/*|*/pages/*|*/api/*|*/server/*|*/client/*|*/utils/*|*/models/*|*/services/*|*/conflation/*|src/*|app/*|lib/*|components/*|conflation/*)
    deny "Main agent should not write business source directly: $FILE. Dispatch implementer."
    exit 2 ;;
esac
allow
exit 0
