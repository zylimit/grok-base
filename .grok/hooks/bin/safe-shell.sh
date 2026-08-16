#!/usr/bin/env bash
# PreToolUse (Bash): deny catastrophic/destructive command patterns.
# Safety guardrail; never bypassed by Fast Mode. Fail-open by design elsewhere,
# so this script must emit an explicit deny to block.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

read_stdin
CMD=$(tool_command)
[ -n "$CMD" ] || { allow; exit 0; }

deny_if() {
  local pattern=$1 reason=$2
  if printf '%s\n' "$CMD" | grep -Eq "$pattern"; then
    deny "$reason"
    exit 2
  fi
}

# rm -rf on filesystem root or home root
deny_if '(^|[;&|[:space:]])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)[[:space:]]+("?/"?|/\*|"?~"?|\$HOME)([[:space:]]|$)' \
  "rm -rf on / or home root is blocked."
# filesystem/device destroyers
deny_if '(^|[;&|[:space:]])mkfs(\.[a-z0-9]+)?([[:space:]]|$)' \
  "mkfs (filesystem format) is blocked."
deny_if '(^|[;&|[:space:]])dd[[:space:]][^;&|]*of=/dev/(sd|hd|nvme|vd|mmcblk)' \
  "dd writing to a block device is blocked."
# fork bomb
deny_if ':\(\)[[:space:]]*\{[[:space:]]*:\|:' \
  "Fork bomb pattern is blocked."
# world-writable root
deny_if '(^|[;&|[:space:]])chmod[[:space:]]+(-[a-zA-Z]*R[a-zA-Z]*[[:space:]]+)?777[[:space:]]+/([[:space:]]|$)' \
  "chmod 777 on / is blocked."
# force-push to protected branches
deny_if '(^|[;&|[:space:]])git[[:space:]]+push[[:space:]][^;&|]*(--force|-f)([[:space:]][^;&|]*)?[[:space:]](origin[[:space:]]+)?(main|master)([[:space:]]|$)' \
  "Force-push to main/master is blocked. Use a feature branch or get explicit approval."
# pipe remote script straight into a shell
deny_if '(^|[;&|[:space:]])(curl|wget)[[:space:]][^;&|]*\|[[:space:]]*(ba|z|da)?sh([[:space:]]|$)' \
  "Piping a remote script into a shell is blocked. Download, inspect, then run."

allow
exit 0
