#!/usr/bin/env bash
# Optional Grok behavior smoke tests (off by default).
set -eu

ROOT=$(cd "$(dirname "$0")/../../../.." && pwd)

if [ "${GROK_BASE_RUN_BEHAVIOR_TESTS:-0}" != "1" ]; then
  echo "test-skill-behavior: skipped (set GROK_BASE_RUN_BEHAVIOR_TESTS=1 to run)"
  exit 0
fi

command -v grok >/dev/null 2>&1 || {
  echo "test-skill-behavior: grok CLI not found" >&2
  exit 1
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/project"
mkdir -p "$TARGET"
cp -R "$ROOT/.grok" "$TARGET/.grok"
cp "$ROOT/AGENTS.md" "$TARGET/AGENTS.md"

run_case() {
  name=$1
  prompt=$2
  pattern=$3
  out="$TMP/$name.out"
  grok -p --yolo --cwd "$TARGET" "$prompt" >"$out" 2>"$TMP/$name.err" || {
    cat "$TMP/$name.err" >&2
    echo "test-skill-behavior: grok failed for $name" >&2
    exit 1
  }
  if ! grep -Eiq "$pattern" "$out"; then
    echo "test-skill-behavior: $name did not match expected behavior" >&2
    cat "$out" >&2
    exit 1
  fi
  echo "test-skill-behavior: $name passed"
}

run_case "bug-routing" \
  "只回答你会先使用哪个流程，不要修改文件：测试报 TypeError，帮我修一下。" \
  "bug-fixer|根因|复现|调试"

echo "test-skill-behavior: passed"
