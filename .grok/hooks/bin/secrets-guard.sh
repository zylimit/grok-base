#!/usr/bin/env bash
# PreToolUse (Read/Edit/Write): deny direct access to secret material.
# Privacy/Security guardrail; never bypassed by Fast Mode.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

read_stdin
PATHS=$(tool_file_paths)
[ -n "$PATHS" ] || { allow; exit 0; }

is_secret_path() {
  local p=$1 base
  base=$(basename -- "$p")
  # allow documented placeholders
  case "$base" in
    .env.example|.env.sample|.env.template|env.example) return 1 ;;
  esac
  case "$base" in
    .env|.env.*) return 0 ;;
    id_rsa*|id_ed25519*|id_ecdsa*|id_dsa*) return 0 ;;
    *.pem|*.p12|*.pfx|*.keystore|*.jks) return 0 ;;
    credentials|credentials.json|.netrc|.npmrc|.pypirc) return 0 ;;
  esac
  case "$p" in
    */.ssh/*|*/.aws/*|*/.gnupg/*|*/.grok/auth/*) return 0 ;;
  esac
  return 1
}

while IFS= read -r p; do
  [ -n "$p" ] || continue
  if is_secret_path "$p"; then
    deny "Access to secret material is blocked: $p. Use environment variables or a documented placeholder (.env.example)."
    exit 2
  fi
done <<EOF
$PATHS
EOF

allow
exit 0
