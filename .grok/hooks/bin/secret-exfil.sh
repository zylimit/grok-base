#!/bin/bash
# PreToolUse (Bash|run_terminal_command): block secret read/copy/exfil.
# Safety rail; Fast Mode does NOT exempt. Fail-open if command is empty.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

read_stdin
CMD=$(tool_command)
[ -n "$CMD" ] || { allow; exit 0; }

strip_examples() {
  printf '%s' "$1" | sed -E 's/\.env\.(example|sample|template|dist)[A-Za-z0-9_.-]*//g'
}

# Peel sudo/nohup/nice/timeout/env and bash|sh -c quotes (max 5 layers).
strip_wrappers() {
  local c="$1" prev="" i=0
  while [ "$c" != "$prev" ] && [ "$i" -lt 5 ]; do
    prev="$c"
    i=$((i + 1))
    c=$(printf '%s' "$c" | sed -E \
      -e 's/^[[:space:]]+//' \
      -e 's/^sudo[[:space:]]+//' \
      -e 's/^nohup[[:space:]]+//' \
      -e 's/^nice([[:space:]]+-n[[:space:]]*[0-9]+)?[[:space:]]+//' \
      -e 's/^timeout([[:space:]]+--?[A-Za-z-]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+[0-9]+[smhd]?[[:space:]]+//' \
      -e 's/^env([[:space:]]+[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*)*[[:space:]]+//' \
      -e "s/^(ba|z|da)?sh[[:space:]]+-l?c[[:space:]]+[\"']?//" \
      -e "s/[\"']\$//")
  done
  printf '%s' "$c"
}

SECRET_CORE='(\.env(\.[A-Za-z0-9_-]+)?|id_rsa[A-Za-z0-9_.-]*|id_ed25519[A-Za-z0-9_.-]*|id_ecdsa[A-Za-z0-9_.-]*|id_dsa[A-Za-z0-9_.-]*|[^[:space:]]*\.(pem|p12|pfx|keystore|jks|ppk)|credentials\.json|credentials|\.netrc|\.npmrc|\.pypirc|\.aws/credentials|\.ssh/[^[:space:]]+|\.gnupg/[^[:space:]]+|\.grok/auth/[^[:space:]]+)([[:space:]"'"'"']|$)'
ARGPFX='[[:space:]]+([^|;&]*[[:space:]/"'"'"'=@])?'
ANCHOR='(^|;|&&|\|\||`|\$\()[[:space:]]*'

REASON=""
check_one() {
  local c
  c=$(strip_examples "$1")
  if printf '%s' "$c" | grep -qE "${ANCHOR}(cat|less|head|tail|strings|xxd|od)${ARGPFX}${SECRET_CORE}"; then
    REASON="secret-exfil: read of a secret file (cat/less/head/tail/strings/xxd/od + .env/key material)"
    return 0
  fi
  if printf '%s' "$c" | grep -qE "${ANCHOR}(cp|scp|rsync|mv)${ARGPFX}${SECRET_CORE}"; then
    REASON="secret-exfil: copy/move of a secret file (cp/scp/rsync/mv)"
    return 0
  fi
  if printf '%s' "$c" | grep -qE "${ANCHOR}(env|printenv)[[:space:]].*\|[[:space:]]*(curl|wget|nc)\b|${ANCHOR}(env|printenv)[[:space:]]*\|[[:space:]]*(curl|wget|nc)\b"; then
    REASON="secret-exfil: env/printenv piped to curl/wget/nc"
    return 0
  fi
  if printf '%s' "$c" | grep -qE "${ANCHOR}(curl|wget|nc)${ARGPFX}${SECRET_CORE}"; then
    REASON="secret-exfil: network command carrying a secret file (curl/wget/nc)"
    return 0
  fi
  return 1
}

STRIPPED=$(strip_wrappers "$CMD")
if check_one "$CMD" || { [ "$STRIPPED" != "$CMD" ] && check_one "$STRIPPED"; }; then
  deny "$REASON"
  exit 2
fi
allow
exit 0
