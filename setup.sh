#!/usr/bin/env bash
# setup.sh - inject grok-base into a target project (macOS / Linux).
# Usage: ./setup.sh [target_dir]    default: current directory
set -eu

die() { printf 'setup: %s\n' "$1" >&2; exit 1; }
ok() { printf '[ok] %s\n' "$1"; }
warn() { printf '[!] %s\n' "$1" >&2; }

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd) || die "cannot resolve script dir"
SRC_GROK="$SCRIPT_DIR/.grok"
SRC_AGENTS="$SCRIPT_DIR/AGENTS.md"
[ -d "$SRC_GROK" ] || die "no .grok under setup dir (run from grok-base root)"
[ -f "$SRC_AGENTS" ] || die "no AGENTS.md under setup dir"

TARGET=${1:-.}
case "$TARGET" in *..*) die "unsafe target: $TARGET" ;; esac
mkdir -p "$TARGET" || die "cannot create target"
TARGET=$(cd "$TARGET" && pwd) || die "cannot resolve target"
TARGET_GROK="$TARGET/.grok"
TARGET_AGENTS="$TARGET/AGENTS.md"

printf '=== grok-base setup (Unix) ===\n'
printf 'target: %s\n' "$TARGET"

command -v git >/dev/null 2>&1 && ok "git: $(git --version 2>/dev/null | head -1)" || warn 'git not detected'
command -v bash >/dev/null 2>&1 && ok 'bash available' || die 'bash required'
command -v grok >/dev/null 2>&1 && ok 'grok CLI detected' || warn 'grok CLI not detected (optional)'

norm_sha() { tr -d '\r' <"$1" | sha256sum | awk '{print $1}'; }

copy_file() {
  local src=$1 dest=$2 mode=${3:-}
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && ! cmp -s "$src" "$dest"; then
    cp -p "$dest" "$dest.bak"
    printf 'backup: %s.bak\n' "$dest"
  fi
  cp -p "$src" "$dest"
  [ -n "$mode" ] && chmod "$mode" "$dest"
}

OLD_MANIFEST=""
FRAMEWORK_NEW_LIST=""
[ -f "$TARGET_GROK/FRAMEWORK-MANIFEST.txt" ] && OLD_MANIFEST="$TARGET_GROK/FRAMEWORK-MANIFEST.txt"

manifest_sha_of() {
  [ -n "$OLD_MANIFEST" ] || return 0
  awk -F '\t' -v p="$1" '$0 !~ /^#/ && $1 == p { print $2; exit }' "$OLD_MANIFEST"
}

# AGENTS.md
if [ -f "$TARGET_AGENTS" ]; then
  if ! cmp -s "$SRC_AGENTS" "$TARGET_AGENTS"; then
    old_sha=$(manifest_sha_of '../AGENTS.md')
    if [ -n "$old_sha" ] && [ "$(norm_sha "$TARGET_AGENTS")" = "$old_sha" ]; then
      copy_file "$SRC_AGENTS" "$TARGET_AGENTS"
      ok 'AGENTS.md upgraded'
    else
      cp -p "$SRC_AGENTS" "$TARGET_AGENTS.framework-new"
      FRAMEWORK_NEW_LIST="${FRAMEWORK_NEW_LIST}AGENTS.md
"
      warn 'AGENTS.md differs; wrote AGENTS.md.framework-new'
    fi
  else
    ok 'AGENTS.md already up to date'
  fi
else
  copy_file "$SRC_AGENTS" "$TARGET_AGENTS"
  ok 'AGENTS.md installed'
fi

# Copy .grok tree
mkdir -p "$TARGET_GROK"
while IFS= read -r -d '' src; do
  rel=${src#"$SRC_GROK"/}
  case "$rel" in
    FRAMEWORK-MANIFEST.txt) continue ;;
    hooks/project-hooks.json) continue ;;  # regenerated for Unix
    settings.local.json|config.local.toml) continue ;;
    .needs-review|.needs-review.lock|.fast-mode|.stop-reminder|.feedback-signal) continue ;;
    .subagent-reminded|.tdd-exempt|.red-verified|.static-gate|.degraded-review) continue ;;
    signals.jsonl|*/signals.jsonl) continue ;;
    evidence/*) continue ;;
    *.bak|*.framework-new) continue ;;
    feedback/templates/*) ;;
    feedback/*/*) ;;
    feedback/*.md) continue ;;
  esac
  dest="$TARGET_GROK/$rel"
  mode=""
  case "$rel" in
    hooks/bin/*.sh|scripts/*.sh) mode=0755 ;;
  esac
  if [ -e "$dest" ] && ! cmp -s "$src" "$dest"; then
    old_sha=$(manifest_sha_of "$rel")
    if [ -n "$old_sha" ] && [ "$(norm_sha "$dest")" = "$old_sha" ]; then
      :
    else
      cp -p "$src" "$dest.framework-new"
      [ -n "$mode" ] && chmod "$mode" "$dest.framework-new"
      FRAMEWORK_NEW_LIST="${FRAMEWORK_NEW_LIST}${rel}
"
      continue
    fi
  fi
  copy_file "$src" "$dest" "$mode"
done < <(find "$SRC_GROK" -type f -print0)

# chmod hook scripts
find "$TARGET_GROK/hooks/bin" -type f -name '*.sh' -exec chmod 0755 {} \; 2>/dev/null || true
find "$TARGET_GROK/scripts" -type f -name '*.sh' -exec chmod 0755 {} \; 2>/dev/null || true
ok '.grok framework files copied'

# Unix hooks JSON (bash .sh entrypoints)
HOOKS_JSON="$TARGET_GROK/hooks/project-hooks.json"
mkdir -p "$(dirname "$HOOKS_JSON")"
if [ -f "$HOOKS_JSON" ]; then
  cp -p "$HOOKS_JSON" "$HOOKS_JSON.bak" 2>/dev/null || true
fi
cat >"$HOOKS_JSON" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"${GROK_WORKSPACE_ROOT}/.grok/hooks/bin/session-start.sh\"", "timeout": 10 },
          { "type": "command", "command": "bash \"${GROK_WORKSPACE_ROOT}/.grok/hooks/bin/session-rules-banner.sh\"", "timeout": 5 }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"${GROK_WORKSPACE_ROOT}/.grok/hooks/bin/detect-feedback.sh\"", "timeout": 5 }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash|run_terminal_command",
        "hooks": [
          { "type": "command", "command": "bash \"${GROK_WORKSPACE_ROOT}/.grok/hooks/bin/block-pkill.sh\"", "timeout": 5 },
          { "type": "command", "command": "bash \"${GROK_WORKSPACE_ROOT}/.grok/hooks/bin/pre-commit-check.sh\"", "timeout": 30 }
        ]
      },
      {
        "matcher": "Edit|Write|MultiEdit|search_replace",
        "hooks": [
          { "type": "command", "command": "bash \"${GROK_WORKSPACE_ROOT}/.grok/hooks/bin/no-direct-code-guard.sh\"", "timeout": 5 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit|search_replace",
        "hooks": [
          { "type": "command", "command": "bash \"${GROK_WORKSPACE_ROOT}/.grok/hooks/bin/mark-review.sh\"", "timeout": 5 }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"${GROK_WORKSPACE_ROOT}/.grok/hooks/bin/stop-reminder.sh\"", "timeout": 5 }
        ]
      }
    ]
  }
}
EOF
ok 'project-hooks.json written (Unix bash entrypoints)'

# Reset feedback index
FB_TPL="$SRC_GROK/feedback/templates/feedback-index-template.md"
FB_INDEX="$TARGET_GROK/feedback/FEEDBACK-INDEX.md"
if [ -f "$FB_TPL" ]; then
  mkdir -p "$(dirname "$FB_INDEX")"
  copy_file "$FB_TPL" "$FB_INDEX"
  ok 'FEEDBACK-INDEX.md reset from template'
fi

# Manifest
if [ -f "$SRC_GROK/FRAMEWORK-MANIFEST.txt" ]; then
  copy_file "$SRC_GROK/FRAMEWORK-MANIFEST.txt" "$TARGET_GROK/FRAMEWORK-MANIFEST.txt"
  ok 'FRAMEWORK-MANIFEST.txt installed'
else
  warn 'FRAMEWORK-MANIFEST.txt missing in source (run .grok/scripts/gen-manifest.sh)'
fi

if [ -n "$FRAMEWORK_NEW_LIST" ]; then
  warn 'user-modified files NOT overwritten; see *.framework-new:'
  printf '%s' "$FRAMEWORK_NEW_LIST" | while IFS= read -r f; do
    [ -n "$f" ] && printf '  - %s\n' "$f"
  done
fi

skills=$(find "$TARGET_GROK/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
agents=$(find "$TARGET_GROK/agents" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
ok "installed skills=$skills agents=$agents"

if [ -f "$TARGET_GROK/scripts/doctor.sh" ]; then
  printf '=== doctor ===\n'
  bash "$TARGET_GROK/scripts/doctor.sh" "$TARGET" || warn "doctor reported issues"
fi

printf '\nDone. Open the target project in Grok.\n'
printf '  - Trust hooks if prompted: /hooks-trust or grok --trust\n'
printf '  - Reload hooks after install (restart session)\n'
exit 0
