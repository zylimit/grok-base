#!/usr/bin/env bash
# PreToolUse edit: block main agent writing business source
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

fast_mode_active 2>/dev/null && { grok_allow; exit 0; }
read_hook_json 2>/dev/null || true
INPUT=${HOOK_RAW:-$(cat || true)}
FILE=""
if command -v jq >/dev/null 2>&1; then
  FILE=$(printf '%s' "$INPUT" | jq -r '.toolInput.file_path // .toolInput.path // .toolInput.target_file // .tool_input.file_path // empty' 2>/dev/null || true)
fi
[ -n "$FILE" ] || { grok_allow; exit 0; }
FP=$(printf '%s' "$FILE" | tr '\\' '/')

case "$FP" in
  *.md|*.json|*.toml|*.cmd|*.ps1|*.sh|.grok/*|*/.grok/*|*AGENTS.md*|*Product-Spec*|*DEV-PLAN*|*progress.md*|*CHANGELOG*|*feedback*|*agents*|*skills*|*hooks*|*roles*|*personas*)
    grok_allow; exit 0 ;;
esac

case "$FP" in
  */src/*|*/app/*|*/lib/*|*/components/*|*/pages/*|*/api/*|*/server/*|*/client/*|*/utils/*|*/models/*|*/services/*|*/conflation/*|src/*|app/*|lib/*|components/*|conflation/*)
    grok_deny "Main agent should not write business source directly: $FILE. Dispatch implementer."
    exit 2 ;;
esac
grok_allow
exit 0
