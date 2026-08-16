#!/usr/bin/env bash
# PreToolUse: deny pkill -f (safety; never bypassed by Fast Mode).
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

read_stdin
CMD=$(tool_command)
[ -n "$CMD" ] || { allow; exit 0; }

if printf '%s\n' "$CMD" | grep -Eq '(^|[;&|[:space:]])pkill[[:space:]][^;&|]*-f([[:space:]]|$)'; then
  deny "pkill -f is blocked. Inspect exact PIDs first, then kill by PID."
  exit 2
fi
allow
exit 0
