#!/usr/bin/env bash
# SessionStart: surface Fast Mode, pending review, feedback signal, dirty tree.
set -u
BIN_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib.sh
. "$BIN_DIR/lib.sh"

ROOT=$(project_root) || exit 0
FLAG=$(fast_mode_flag)

if fast_mode_active; then
  expiry=$(sed -n 's/^expires_epoch=//p' "$FLAG" | head -1)
  now=$(date +%s)
  left=$(( (expiry - now + 59) / 60 ))
  printf 'FAST-MODE ON: about %s minutes remaining. Skip auto review/test gates; safety guards stay on.\n' "$left"
elif [ -f "$FLAG" ]; then
  printf '%s\n' 'FAST-MODE EXPIRED: normal quality workflow is active again.'
else
  printf '%s\n' 'FAST-MODE OFF: normal quality workflow is active.'
fi

STATE="$ROOT/.grok/.needs-review"
if [ -f "$STATE" ]; then
  FILES=$(grep -vE '^[[:space:]]*$' "$STATE" 2>/dev/null | grep -vx "clean" || true)
  if [ -n "$FILES" ]; then
    COUNT=$(printf '%s\n' "$FILES" | wc -l | tr -d ' ')
    printf 'REVIEW PENDING: %s file(s). Dispatch code-reviewer; after pass write clean to .grok/.needs-review.\n' "$COUNT"
  fi
fi

[ -f "$ROOT/.grok/.feedback-signal" ] && \
  printf '%s\n' 'FEEDBACK SIGNAL: after handling the user request, dispatch feedback-observer.'

if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  N=$(git -C "$ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "${N:-0}" -gt 0 ]; then
    printf 'Dirty worktree: %s change(s). Prefer /recap: progress.md + Product-Spec.md + Product-Spec-CHANGELOG.md.\n' "$N"
  fi
fi

INDEX="$ROOT/.grok/feedback/FEEDBACK-INDEX.md"
if [ -f "$INDEX" ]; then
  PENDING=$(grep -cE '^\- \[' "$INDEX" 2>/dev/null || true)
  if [ "${PENDING:-0}" -gt 0 ] 2>/dev/null; then
    printf 'Feedback index has pending entries. Consider dispatching evolution-runner.\n'
  fi
fi

exit 0
