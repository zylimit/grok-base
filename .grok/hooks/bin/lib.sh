#!/bin/bash
# Shared helpers for Grok project hooks.
# Env (injected by Grok): GROK_WORKSPACE_ROOT, CLAUDE_PROJECT_DIR, GROK_SESSION_ID, GROK_HOOK_EVENT
# GROK_HOOK_NAME is optional; if unset, fall back to the sourcing hook script name.

set -u

project_root() {
  if [ -n "${GROK_WORKSPACE_ROOT:-}" ] && [ -d "$GROK_WORKSPACE_ROOT" ]; then
    printf '%s' "$GROK_WORKSPACE_ROOT"
    return 0
  fi
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  # Fallback: this file is at <root>/.grok/hooks/bin/lib.sh
  local here
  here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || return 1
  cd "$here/../../.." && pwd -P
}

read_stdin() {
  HOOK_JSON=$(cat || true)
  export HOOK_JSON
}

tool_command() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "${HOOK_JSON:-}" | jq -r '.toolInput.command // .tool_input.command // empty' 2>/dev/null || true
    return 0
  fi
  printf '%s' "${HOOK_JSON:-}" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

tool_file_paths() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "${HOOK_JSON:-}" | jq -r '
      [
        .toolInput.file_path, .toolInput.path, .toolInput.target_file,
        .tool_input.file_path, .tool_input.path
      ] | map(select(type == "string" and length > 0)) | .[]
    ' 2>/dev/null || true
    return 0
  fi
  # Fallback without jq: extract common path keys so guards do not silently
  # fail open (audit: implicit jq dependency).
  printf '%s' "${HOOK_JSON:-}" \
    | sed -n 's/.*"\(file_path\|path\|target_file\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p' \
    | head -5
}

# Append one deny line to .grok/hooks/gate-log.tsv. Write failure is ignored (fail-open).
_append_gate_log() {
  local reason=$1
  local root hook ts sanitized log
  root=$(project_root 2>/dev/null) || return 0
  [ -n "$root" ] || return 0
  hook=${GROK_HOOK_NAME:-unknown}
  ts=$(date +%s 2>/dev/null) || return 0
  sanitized=$(printf '%s' "$reason" | tr '\t\r\n' '   ' | cut -c1-240)
  log="$root/.grok/hooks/gate-log.tsv"
  mkdir -p "$(dirname -- "$log")" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\n' "$ts" "$hook" "deny" "$sanitized" >>"$log" 2>/dev/null || true
}

deny() {
  local reason=$1
  _append_gate_log "$reason" || true
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg r "$reason" '{decision:"deny",reason:$r}'
  else
    printf '{"decision":"deny","reason":"%s"}\n' "$(printf '%s' "$reason" | sed 's/"/\\"/g')"
  fi
}

allow() {
  printf '%s\n' '{"decision":"allow"}'
}

fast_mode_flag() {
  printf '%s/.grok/.fast-mode\n' "$(project_root)"
}

fast_mode_active() {
  local flag expiry now
  flag=$(fast_mode_flag)
  [ -f "$flag" ] || return 1
  expiry=$(sed -n 's/^expires_epoch=//p' "$flag" 2>/dev/null | head -1)
  case "$expiry" in ''|*[!0-9]*) return 1 ;; esac
  now=$(date +%s 2>/dev/null) || return 1
  [ "$expiry" -gt "$now" ]
}

# Blob fingerprint for .needs-review: git hash-object, else sha256sum.
file_fingerprint() {
  local root=$1 abs=$2 out
  if command -v git >/dev/null 2>&1 && git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    out=$(git -C "$root" hash-object -- "$abs" 2>/dev/null) || out=""
    if [ -n "$out" ]; then
      printf '%s' "$out"
      return 0
    fi
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    out=$(sha256sum -- "$abs" 2>/dev/null | awk '{print $1}')
    if [ -n "$out" ]; then
      printf '%s' "$out"
      return 0
    fi
  fi
  return 1
}

# When sourced by a hook, name the log row even if the host omitted GROK_HOOK_NAME.
if [ -z "${GROK_HOOK_NAME:-}" ]; then
  GROK_HOOK_NAME=$(basename -- "${BASH_SOURCE[1]:-unknown}")
  GROK_HOOK_NAME=${GROK_HOOK_NAME%.sh}
  GROK_HOOK_NAME=${GROK_HOOK_NAME%.ps1}
  [ -n "$GROK_HOOK_NAME" ] || GROK_HOOK_NAME=unknown
  export GROK_HOOK_NAME
fi
