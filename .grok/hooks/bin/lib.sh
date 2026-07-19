#!/usr/bin/env bash
# Shared helpers for Grok project hooks.
# Env (injected by Grok): GROK_WORKSPACE_ROOT, CLAUDE_PROJECT_DIR, GROK_SESSION_ID, GROK_HOOK_EVENT

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
  fi
}

deny() {
  local reason=$1
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
