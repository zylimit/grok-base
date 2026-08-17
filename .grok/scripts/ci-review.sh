#!/usr/bin/env bash
# Headless review gate for CI (grok -p, read-only tool surface).
# Template: adjust the prompt/rules to your pipeline, then wire into CI:
#   bash .grok/scripts/ci-review.sh origin/main...HEAD
# Requires: grok CLI installed and authenticated (XAI_API_KEY in CI secrets).
# Exit 0 = PASS verdict, exit 1 = FAIL verdict or no verdict.
set -u

RANGE=${1:-origin/main...HEAD}

if ! command -v grok >/dev/null 2>&1; then
  echo "ci-review: grok CLI not found" >&2
  exit 1
fi

PROMPT="You are a review gate. Review the diff of ${RANGE} in this repo:
1) run static gate: bash .grok/scripts/static-check.sh
2) run boundary gate: bash .grok/scripts/arch-check.sh
3) run fitness gate: bash .grok/scripts/fitness.sh
4) run ADR wiring gate: bash .grok/scripts/adr-check.sh
5) review the diff (git diff ${RANGE}) against the five quality attributes in .grok/rules/quality-attributes.md: hardcoded secrets, missing timeout/retry on new external calls, swallowed errors, sensitive data in logs, unsafe destructive operations.
Cite file:line for every finding. End your reply with exactly one line: VERDICT: PASS or VERDICT: FAIL"

OUT=$(grok -p "$PROMPT" \
  --allow 'Read' \
  --allow 'Grep' \
  --allow 'Bash(git diff*)' \
  --allow 'Bash(git log*)' \
  --allow 'Bash(bash .grok/scripts/static-check.sh*)' \
  --allow 'Bash(bash .grok/scripts/arch-check.sh*)' \
  --allow 'Bash(bash .grok/scripts/fitness.sh*)' \
  --allow 'Bash(bash .grok/scripts/adr-check.sh*)' \
  --deny 'Edit' \
  --deny 'Bash(rm *)' \
  2>&1)
RC=$?

printf '%s\n' "$OUT"

if [ $RC -ne 0 ]; then
  echo "ci-review: grok exited $RC" >&2
  exit 1
fi

if printf '%s' "$OUT" | grep -q 'VERDICT: PASS'; then
  exit 0
fi
echo "ci-review: gate FAILED (no PASS verdict)" >&2
exit 1
