#!/usr/bin/env bash
# UserPromptSubmit: record a local signal file when correction phrases appear.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

ROOT=$(project_root) || exit 0
read_stdin
PROMPT=""
if command -v jq >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$HOOK_JSON" | jq -r '.prompt // .message // .userPrompt // empty' 2>/dev/null || true)
fi
[ -n "$PROMPT" ] || exit 0

if printf '%s' "$PROMPT" | grep -Eqi '不是这样|别这样做|你搞错|搞错了|你错了|不对|不应该|你漏了|你忘了|改一下|不合理|你理解错|我说的不是|为什么没|没有执行|没有生效|不要再|别再|停下|先不要|能不能|wrong|incorrect|stop doing|do not|don.t'; then
  printf 'detected_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$ROOT/.grok/.feedback-signal"
fi
exit 0
