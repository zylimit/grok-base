#!/usr/bin/env bash
# Install-surface regression: setup.sh into a temp dir (never onto this source repo).
# Asserts Unix JSON (bin/*.sh + secret-exfil + PreCompact), no leftover .cmd, doctor green.
set -eu

SRC=$(cd "$(dirname "$0")/../.." && pwd) || { echo "test-setup: cannot resolve source" >&2; exit 1; }
[ -f "$SRC/setup.sh" ] || { echo "test-setup: no setup.sh at $SRC" >&2; exit 1; }
[ -d "$SRC/.grok" ] || { echo "test-setup: no .grok at $SRC" >&2; exit 1; }

TMP=$(mktemp -d) || { echo "test-setup: mktemp failed" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

if [ "$TMP" = "$SRC" ]; then
  echo "test-setup: refuse — temp dir resolved to source (SCRIPT_DIR==TARGET)" >&2
  exit 1
fi

echo "test-setup: SRC=$SRC"
echo "test-setup: TMP=$TMP"
bash "$SRC/setup.sh" "$TMP"

cmd_n=$(find "$TMP/.grok/hooks/bin" -maxdepth 1 -type f -name '*.cmd' 2>/dev/null | wc -l | tr -d ' ')
if [ "${cmd_n:-0}" -ne 0 ]; then
  echo "test-setup: FAIL — Unix install left hooks/bin/*.cmd ($cmd_n)" >&2
  find "$TMP/.grok/hooks/bin" -maxdepth 1 -name '*.cmd' >&2 || true
  exit 1
fi
echo "test-setup: no hooks/bin/*.cmd"

JSON="$TMP/.grok/hooks/project-hooks.json"
[ -f "$JSON" ] || { echo "test-setup: FAIL — project-hooks.json missing" >&2; exit 1; }
for needle in 'bin/safe-shell.sh' 'bin/secret-exfil.sh' 'PreCompact'; do
  if ! grep -q "$needle" "$JSON"; then
    echo "test-setup: FAIL — project-hooks.json missing $needle" >&2
    exit 1
  fi
done
echo "test-setup: project-hooks.json has safe-shell.sh, secret-exfil.sh, PreCompact"

if [ -e "$TMP/plugins" ] || [ -e "$TMP/.grok-plugin" ]; then
  echo "test-setup: FAIL — plugin marketplace copied into business repo" >&2
  exit 1
fi
echo "test-setup: plugin not copied into business repo"

if ! bash "$TMP/.grok/scripts/doctor.sh" "$TMP"; then
  echo "test-setup: FAIL — doctor.sh failed on installed target" >&2
  exit 1
fi

echo "test-setup: PASS"
exit 0
