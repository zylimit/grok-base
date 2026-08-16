#!/usr/bin/env bash
# PreToolUse: light compile/syntax gate when the command is git commit.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

ROOT=$(project_root) || { allow; exit 0; }
read_stdin
CMD=$(tool_command)
printf '%s\n' "$CMD" | grep -Eq 'git[[:space:]]+commit' || { allow; exit 0; }
fast_mode_active && { allow; exit 0; }

FAILED=0
mapfile -t STAGED < <(git -C "$ROOT" diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
[ "${#STAGED[@]}" -eq 0 ] && { allow; exit 0; }

if printf '%s\n' "${STAGED[@]}" | grep -Eq '\.(ts|tsx)$' && command -v npx >/dev/null 2>&1; then
  TSCONFIG=$(find "$ROOT" -maxdepth 3 -name tsconfig.json \
    ! -path '*/node_modules/*' ! -path '*/.next/*' 2>/dev/null | head -1)
  if [ -n "$TSCONFIG" ]; then
    (cd "$(dirname "$TSCONFIG")" && npx --no-install tsc --noEmit) || FAILED=1
  fi
fi

PY=()
for f in "${STAGED[@]}"; do
  case "$f" in *.py) PY+=("$ROOT/$f") ;; esac
done
if [ "${#PY[@]}" -gt 0 ]; then
  if command -v ruff >/dev/null 2>&1; then
    ruff check "${PY[@]}" || FAILED=1
  elif command -v python3 >/dev/null 2>&1; then
    for f in "${PY[@]}"; do python3 -m py_compile "$f" || FAILED=1; done
  elif command -v python >/dev/null 2>&1; then
    for f in "${PY[@]}"; do python -m py_compile "$f" || FAILED=1; done
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  deny "Pre-commit compile/syntax gate failed."
  exit 2
fi
allow
exit 0
