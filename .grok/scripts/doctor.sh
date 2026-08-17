#!/usr/bin/env bash
# doctor.sh - verify grok-base install
# Usage: bash .grok/scripts/doctor.sh [target_dir]
set -u
ROOT="${1:-.}"
case "$ROOT" in *..*) echo "doctor: unsafe path $ROOT" >&2; exit 2 ;; esac
cd "$ROOT" 2>/dev/null || { echo "doctor: cannot enter $ROOT" >&2; exit 2; }

fail=0
warn=0
ok() { printf '[ok] %s\n' "$1"; }
bad() { printf '[x] %s\n' "$1" >&2; fail=$((fail + 1)); }
note() { printf '[!] %s\n' "$1" >&2; warn=$((warn + 1)); }

printf '=== grok-base doctor ===\n'
printf 'target: %s\n' "$(pwd)"

[ -f AGENTS.md ] && ok 'AGENTS.md exists' || bad 'AGENTS.md missing'
[ -d .grok ] && ok '.grok exists' || { bad '.grok missing'; exit 1; }

for r in architect implementer code-reviewer tester deployer feedback-observer evolution-runner progress-recorder; do
  [ -f ".grok/agents/$r.md" ] && ok "agent $r" || bad "agent $r missing"
  [ -f ".grok/roles/$r.toml" ] && ok "role $r" || bad "role $r missing"
  [ -f ".grok/personas/$r.toml" ] && ok "persona $r" || bad "persona $r missing"
done

rules=$(find .grok/rules -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
[ "${rules:-0}" -ge 3 ] && ok "rules count=$rules" || bad "rules count low: $rules"
[ -f .grok/config.toml ] && ok 'config.toml (permission baseline)' || note 'config.toml missing'
[ -f .grok/sandbox.toml ] && ok 'sandbox.toml (profiles)' || note 'sandbox.toml missing'
[ -f .grok/arch/boundaries.txt ] && ok 'arch/boundaries.txt' || note 'arch/boundaries.txt missing'
for s in static-check arch-check codemap fitness adr-check; do
  [ -f ".grok/scripts/$s.sh" ] && ok "script $s.sh" || bad "script $s.sh missing"
done
[ -f .grok/scripts/test-setup.sh ] && ok 'script test-setup.sh'
for s in adapters prune release-scan gate-audit; do
  [ -f ".grok/scripts/$s.sh" ] && ok "script $s.sh"
done

# Architecture declared but boundaries unwired: note only (source scaffold is this way).
has_arch=0
[ -f Architecture.md ] && has_arch=1
if [ -d docs/adr ] && find docs/adr -maxdepth 1 -type f -name '*.md' -print -quit 2>/dev/null | grep -q .; then
  has_arch=1
fi
if [ "$has_arch" -eq 1 ]; then
  if [ ! -f .grok/arch/boundaries.txt ]; then
    note 'ARCH_UNWIRED: Architecture.md/docs/adr present but .grok/arch/boundaries.txt missing'
  else
    live=$(grep -vE '^[[:space:]]*(#|$)' .grok/arch/boundaries.txt 2>/dev/null | head -1 || true)
    if [ -z "$live" ]; then
      note 'ARCH_UNWIRED: Architecture.md/docs/adr present but boundaries.txt has no live rules'
    fi
  fi
fi

skills=0
for d in .grok/skills/*/; do
  [ -d "$d" ] || continue
  skills=$((skills + 1))
  [ -f "${d}SKILL.md" ] && ok "skill $(basename "$d")" || bad "skill $(basename "$d") missing SKILL.md"
done
[ "$skills" -ge 10 ] && ok "skills count=$skills" || bad "skills count low: $skills"

wf=$(find .grok/workflows -maxdepth 1 -type f -name '*.rhai' 2>/dev/null | wc -l | tr -d ' ')
if [ "${wf:-0}" -gt 0 ]; then
  ok "workflows rhai=$wf"
fi
cmds=$(find .grok/commands -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "${cmds:-0}" -gt 0 ]; then
  ok "commands md=$cmds"
fi

if [ -f .grok/hooks/project-hooks.json ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json; json.load(open('.grok/hooks/project-hooks.json',encoding='utf-8'))" \
      && ok 'project-hooks.json valid JSON' || bad 'project-hooks.json invalid JSON'
    # Linux/macOS: Grok spawns command as an executable relative to the JSON file.
    # .cmd is DOS batch (Permission denied os error 13). Official form is bin/*.sh.
    hook_cmds=$(python3 -c "
import json
d=json.load(open('.grok/hooks/project-hooks.json',encoding='utf-8'))
def walk(o):
    if isinstance(o, dict):
        c=o.get('command')
        if isinstance(c, str):
            print(c)
        for v in o.values():
            walk(v)
    elif isinstance(o, list):
        for v in o:
            walk(v)
walk(d)
" 2>/dev/null || true)
    if [ -z "${hook_cmds:-}" ]; then
      bad 'project-hooks.json has no command entries'
    else
      while IFS= read -r cmd; do
        [ -n "$cmd" ] || continue
        case "$cmd" in
          *.cmd)
            bad "hooks command is Windows .cmd (Linux spawn fails): $cmd"
            continue
            ;;
        esac
        case "$cmd" in
          bin/*.sh)
            if [ -x ".grok/hooks/$cmd" ]; then
              ok "hooks command executable: $cmd"
            else
              bad "hooks command not executable relative to .grok/hooks/: $cmd"
            fi
            ;;
          *)
            bad "hooks command must be bin/<name>.sh (relative to JSON): $cmd"
            ;;
        esac
      done <<EOF
$hook_cmds
EOF
    fi
  else
    note 'python3 missing; skip JSON parse'
  fi
else
  bad 'project-hooks.json missing'
fi

shs=$(find .grok/hooks/bin -maxdepth 1 -type f -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
[ "${shs:-0}" -ge 6 ] && ok "sh hooks=$shs" || bad "sh hooks low: $shs"

# Source repo keeps Windows .cmd next to Unix .sh; that is expected, not a fail.
cmd_n=$(find .grok/hooks/bin -maxdepth 1 -type f -name '*.cmd' 2>/dev/null | wc -l | tr -d ' ')
if [ "${cmd_n:-0}" -gt 0 ]; then
  note "hooks/bin has $cmd_n .cmd file(s) (Windows source assets; Unix install does not use them)"
fi

# spawn smoke
if [ -x .grok/hooks/bin/block-pkill.sh ] || [ -f .grok/hooks/bin/block-pkill.sh ]; then
  export GROK_WORKSPACE_ROOT
  GROK_WORKSPACE_ROOT=$(pwd)
  out=$(printf '%s' '{"toolInput":{"command":"echo hi"}}' | bash .grok/hooks/bin/block-pkill.sh 2>/dev/null || true)
  printf '%s' "$out" | grep -q allow && ok 'spawn smoke block-pkill.sh' || bad "spawn smoke failed: $out"
fi

if [ -f .grok/hooks/bin/no-direct-code-guard.sh ]; then
  export GROK_WORKSPACE_ROOT
  GROK_WORKSPACE_ROOT=$(pwd)
  out=$(printf '%s' '{"toolInput":{"file_path":"progress.md"}}' | bash .grok/hooks/bin/no-direct-code-guard.sh 2>&1 || true)
  printf '%s' "$out" | grep -q '{"decision":"allow"}' && ! printf '%s' "$out" | grep -q 'command not found' \
    && ok 'spawn smoke no-direct-code-guard.sh allow docs' \
    || bad "spawn smoke no-direct-code-guard allow docs failed: $out"
  out=$(printf '%s' '{"toolInput":{"file_path":"src/app.ts"}}' | bash .grok/hooks/bin/no-direct-code-guard.sh 2>&1 || true)
  printf '%s' "$out" | grep -q '"decision":"deny"' && ! printf '%s' "$out" | grep -q 'command not found' \
    && ok 'spawn smoke no-direct-code-guard.sh deny source' \
    || bad "spawn smoke no-direct-code-guard deny source failed: $out"
  out=$(printf '%s' '{"toolInput":{"file_path":"src/app.ts"},"subagentType":"implementer"}' | bash .grok/hooks/bin/no-direct-code-guard.sh 2>&1 || true)
  printf '%s' "$out" | grep -q '{"decision":"allow"}' && ! printf '%s' "$out" | grep -q 'command not found' \
    && ok 'spawn smoke no-direct-code-guard.sh allow subagent' \
    || bad "spawn smoke no-direct-code-guard allow subagent failed: $out"
fi

command -v git >/dev/null 2>&1 && ok 'git available' || note 'git missing'
command -v bash >/dev/null 2>&1 && ok 'bash available' || bad 'bash missing'

if [ "$fail" -gt 0 ]; then
  echo "doctor: FAILED ($fail error(s))"
  exit 1
fi
if [ "$warn" -gt 0 ]; then
  echo "doctor: passed with warnings ($warn)"
  exit 0
fi
echo 'doctor: passed'
exit 0
