#!/usr/bin/env bash
# Curated external-tool table (probe PATH only; not a wiring engine).
# Usage: bash .grok/scripts/adapters.sh [--strict]
# Default: print PRESENT/MISSING per row, exit 0.
# --strict: any MISSING -> exit 1 (NFR that named the tool is BLOCKED).
set -u

STRICT=0
for a in "$@"; do
  case "$a" in
    --strict) STRICT=1 ;;
    -h|--help)
      printf 'usage: adapters.sh [--strict]\n' >&2
      exit 0
      ;;
    -*)
      printf 'adapters: unknown flag %s\n' "$a" >&2
      exit 2
      ;;
  esac
done

# name<TAB>command<TAB>purpose<TAB>nfr
TABLE='gitleaks	gitleaks	密钥扫描	Security
semgrep	semgrep	SAST	Security
osv-scanner	osv-scanner	依赖 CVE	Security
pip-audit	pip-audit	Python 依赖	Security
npm	npm	npm audit	Security
cargo-audit	cargo-audit	Rust 依赖	Security
shellcheck	shellcheck	shell 静态	Reliability'

printf 'name\tcommand\tpurpose\tnfr\tstatus\n'
present=0
missing=0
while IFS= read -r line || [ -n "${line:-}" ]; do
  [ -n "${line:-}" ] || continue
  name=${line%%	*}
  rest=${line#*	}
  cmd=${rest%%	*}
  rest2=${rest#*	}
  purpose=${rest2%%	*}
  nfr=${rest2#*	}
  if command -v "$cmd" >/dev/null 2>&1; then
    status=PRESENT
    present=$((present + 1))
  else
    status=MISSING
    missing=$((missing + 1))
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$cmd" "$purpose" "$nfr" "$status"
done <<EOF
$TABLE
EOF

printf 'adapters: %s PRESENT, %s MISSING\n' "$present" "$missing"

if [ "$STRICT" -eq 1 ] && [ "$missing" -gt 0 ]; then
  exit 1
fi
exit 0
