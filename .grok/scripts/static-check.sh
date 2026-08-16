#!/usr/bin/env bash
# Stack-aware static gate (Stage 0 of code-review).
# Usage: bash .grok/scripts/static-check.sh [project-root]
# Exit 0 = all detected stacks green (missing tools are skipped, never fatal).
# Exit 1 = at least one static error found.
set -u

ROOT=${1:-.}
cd "$ROOT" || { echo "static-check: bad root: $ROOT" >&2; exit 1; }

FAIL=0
RAN=0

note() { printf '%s\n' "$*"; }

# --- TypeScript / JavaScript ---
if [ -f tsconfig.json ]; then
  if command -v npx >/dev/null 2>&1; then
    RAN=1
    note "== tsc --noEmit =="
    if ! npx --no-install tsc --noEmit 2>&1; then
      FAIL=1
    fi
  else
    note "skip: tsconfig.json found but npx unavailable"
  fi
fi

# --- Python ---
PYFILES=$( (git ls-files '*.py' 2>/dev/null || find . -name '*.py' -not -path './.git/*' -not -path './node_modules/*' -not -path './.venv/*') | head -2000 )
if [ -n "$PYFILES" ]; then
  RAN=1
  if command -v ruff >/dev/null 2>&1; then
    note "== ruff check =="
    if ! printf '%s\n' "$PYFILES" | xargs -r ruff check 2>&1; then FAIL=1; fi
  elif command -v python3 >/dev/null 2>&1; then
    note "== py_compile =="
    if ! printf '%s\n' "$PYFILES" | xargs -r python3 -m py_compile 2>&1; then FAIL=1; fi
  else
    note "skip: python files found but ruff/python3 unavailable"
  fi
fi

# --- Shell ---
SHFILES=$( (git ls-files '*.sh' 2>/dev/null || find . -name '*.sh' -not -path './.git/*' -not -path './node_modules/*') | head -500 )
if [ -n "$SHFILES" ]; then
  if command -v shellcheck >/dev/null 2>&1; then
    RAN=1
    note "== shellcheck =="
    if ! printf '%s\n' "$SHFILES" | xargs -r shellcheck -S error 2>&1; then FAIL=1; fi
  else
    RAN=1
    note "== bash -n =="
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      if ! bash -n "$f" 2>&1; then FAIL=1; fi
    done <<EOF
$SHFILES
EOF
  fi
fi

# --- Rust ---
if [ -f Cargo.toml ] && command -v cargo >/dev/null 2>&1; then
  RAN=1
  note "== cargo check -q =="
  if ! cargo check -q 2>&1; then FAIL=1; fi
fi

# --- Project-provided static command wins as an extra gate ---
if [ -f package.json ] && command -v npx >/dev/null 2>&1; then
  if grep -q '"lint:static"' package.json 2>/dev/null; then
    RAN=1
    note "== npm run lint:static =="
    if ! npm run -s lint:static 2>&1; then FAIL=1; fi
  fi
fi

if [ "$RAN" -eq 0 ]; then
  note "static-check: no recognized stack or no tools available; skipped (green)"
fi

if [ "$FAIL" -ne 0 ]; then
  note "static-check: FAIL"
  exit 1
fi
note "static-check: PASS"
exit 0
