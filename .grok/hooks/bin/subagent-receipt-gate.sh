#!/usr/bin/env bash
# SubagentStop (project agents): require the unified result envelope.
# Blocks the subagent's stop ONCE if the reply lacks "Status:"; second pass
# always lets it stop (stopHookActive check) so it can never loop.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

read_stdin

if command -v jq >/dev/null 2>&1; then
  ACTIVE=$(printf '%s' "${HOOK_JSON:-}" | jq -r '.stopHookActive // false' 2>/dev/null)
  MSG=$(printf '%s' "${HOOK_JSON:-}" | jq -r '.lastAssistantMessage // ""' 2>/dev/null)
else
  case "${HOOK_JSON:-}" in *'"stopHookActive":true'*) ACTIVE=true ;; *) ACTIVE=false ;; esac
  MSG=${HOOK_JSON:-}
fi

# Never block twice in the same turn.
[ "$ACTIVE" = "true" ] && exit 0

case "$MSG" in
  *Status:*|*"Status："*) exit 0 ;;
esac

# Empty message (interrupt/edge) -> stay silent, fail open.
[ -n "$MSG" ] || exit 0

printf '%s\n' '{"decision":"block","reason":"回执缺失：请以统一回执结束——Status(DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED;tester用PASS|FAIL) / Changed / Verified / Not verified / Needs review by / Evidence。"}'
exit 0
