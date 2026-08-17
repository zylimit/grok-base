#!/usr/bin/env bash
# Scan a build directory or release archive for leaked paths / secrets.
# Usage: bash .grok/scripts/release-scan.sh <dir|zip|tar|tar.gz|tgz>
# Any hit -> FAIL exit 1. Missing tar/unzip for an archive -> FAIL (do not fake a scan).
set -u

TARGET=${1:-}
if [ -z "$TARGET" ]; then
  printf 'release-scan: FAIL — missing target (dir or .zip/.tar/.tar.gz/.tgz)\n' >&2
  exit 1
fi
if [ ! -e "$TARGET" ]; then
  printf 'release-scan: FAIL — target missing: %s\n' "$TARGET" >&2
  exit 1
fi

TMP=""
cleanup() { [ -n "${TMP:-}" ] && rm -rf -- "$TMP"; }
trap cleanup EXIT

is_archive() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    *.zip|*.tar|*.tar.gz|*.tgz) return 0 ;;
    *) return 1 ;;
  esac
}

SCAN_ROOT=""
if [ -d "$TARGET" ]; then
  SCAN_ROOT=$(cd -- "$TARGET" && pwd -P) || { printf 'release-scan: FAIL — cannot enter dir\n' >&2; exit 1; }
elif is_archive "$TARGET"; then
  SRC=$(cd -- "$(dirname -- "$TARGET")" && pwd -P)/$(basename -- "$TARGET")
  TMP=$(mktemp -d) || { printf 'release-scan: FAIL — mktemp failed\n' >&2; exit 1; }
  lower=$(printf '%s' "$SRC" | tr '[:upper:]' '[:lower:]')
  case "$lower" in
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        if ! unzip -qq -o "$SRC" -d "$TMP"; then
          printf 'release-scan: FAIL — unzip failed for %s\n' "$SRC" >&2
          exit 1
        fi
      elif command -v python3 >/dev/null 2>&1; then
        if ! python3 - "$SRC" "$TMP" <<'PY'
import sys, zipfile
from pathlib import Path
src, dest = Path(sys.argv[1]), Path(sys.argv[2]).resolve()
with zipfile.ZipFile(src) as zf:
    for info in zf.infolist():
        target = (dest / info.filename).resolve()
        if dest != target and not str(target).startswith(str(dest) + "/"):
            raise SystemExit("unsafe zip path: " + info.filename)
        zf.extract(info, dest)
PY
        then
          printf 'release-scan: FAIL — python zip extract failed for %s\n' "$SRC" >&2
          exit 1
        fi
      else
        printf 'release-scan: FAIL — unzip not in PATH and python3 unavailable; cannot scan zip (not scanned)\n' >&2
        exit 1
      fi
      ;;
    *.tar.gz|*.tgz|*.tar)
      if command -v tar >/dev/null 2>&1; then
        tar_flags='-xf'
        case "$lower" in *.tar.gz|*.tgz) tar_flags='-xzf' ;; esac
        if ! tar $tar_flags "$SRC" -C "$TMP" --no-same-owner; then
          printf 'release-scan: FAIL — tar extract failed for %s\n' "$SRC" >&2
          exit 1
        fi
      elif command -v python3 >/dev/null 2>&1; then
        if ! python3 - "$SRC" "$TMP" <<'PY'
import sys, tarfile
from pathlib import Path
src, dest = Path(sys.argv[1]), Path(sys.argv[2]).resolve()
with tarfile.open(src) as tf:
    for member in tf.getmembers():
        target = (dest / member.name).resolve()
        if dest != target and not str(target).startswith(str(dest) + "/"):
            raise SystemExit("unsafe tar path: " + member.name)
    tf.extractall(dest)
PY
        then
          printf 'release-scan: FAIL — python tar extract failed for %s\n' "$SRC" >&2
          exit 1
        fi
      else
        printf 'release-scan: FAIL — tar not in PATH and python3 unavailable; cannot scan archive (not scanned)\n' >&2
        exit 1
      fi
      ;;
    *)
      printf 'release-scan: FAIL — unsupported archive: %s\n' "$SRC" >&2
      exit 1
      ;;
  esac
  SCAN_ROOT=$TMP
else
  printf 'release-scan: FAIL — not a directory or supported archive: %s\n' "$TARGET" >&2
  exit 1
fi

FAIL=0
hit() {
  printf 'release-scan: FAIL %s\n' "$1"
  FAIL=1
}

# Filename hits (relative to scan root).
while IFS= read -r -d '' f; do
  rel=${f#"$SCAN_ROOT"/}
  base=$(basename -- "$f")
  case "$base" in
    .env|*.pem|*.key|id_rsa|credentials.json|*.db)
      hit "name $base $rel"
      ;;
  esac
  case "$rel" in
    */Users/*|Users/*|*C:\\Users\\*|*C:/Users/*)
      hit "path $rel"
      ;;
  esac
done < <(find "$SCAN_ROOT" -type f -print0 2>/dev/null)

# Content hits. Build patterns without embedding live secret literals as-is where avoidable.
PAT_PATH='/Users/|C:\\Users\\|C:/Users/'
PAT_SK1='sk-ant-'
PAT_SK2='sk-proj-'
PAT_PEM='BEGIN PRIVATE KEY'
PAT_PW='password[[:space:]]*=[[:space:]]*['\''"]'
CONTENT_RE="${PAT_PATH}|${PAT_SK1}|${PAT_SK2}|${PAT_PEM}|${PAT_PW}"

if command -v rg >/dev/null 2>&1; then
  while IFS= read -r line || [ -n "${line:-}" ]; do
    [ -n "${line:-}" ] || continue
    hit "content $line"
  done < <(rg -n --no-heading --hidden -g '!.git/**' -e "$CONTENT_RE" "$SCAN_ROOT" 2>/dev/null || true)
else
  while IFS= read -r line || [ -n "${line:-}" ]; do
    [ -n "${line:-}" ] || continue
    hit "content $line"
  done < <(grep -RInE --binary-files=without-match --exclude-dir=.git -e "$CONTENT_RE" "$SCAN_ROOT" 2>/dev/null || true)
fi

if [ "$FAIL" -ne 0 ]; then
  printf 'release-scan: FAIL\n' >&2
  exit 1
fi
printf 'release-scan: PASS root=%s\n' "$SCAN_ROOT"
exit 0
