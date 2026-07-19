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

for r in implementer code-reviewer tester deployer feedback-observer evolution-runner progress-recorder; do
  [ -f ".grok/agents/$r.md" ] && ok "agent $r" || bad "agent $r missing"
  [ -f ".grok/roles/$r.toml" ] && ok "role $r" || bad "role $r missing"
  [ -f ".grok/personas/$r.toml" ] && ok "persona $r" || bad "persona $r missing"
done

skills=0
for d in .grok/skills/*/; do
  [ -d "$d" ] || continue
  skills=$((skills + 1))
  [ -f "${d}SKILL.md" ] && ok "skill $(basename "$d")" || bad "skill $(basename "$d") missing SKILL.md"
done
[ "$skills" -ge 10 ] && ok "skills count=$skills" || bad "skills count low: $skills"

if [ -f .grok/hooks/project-hooks.json ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json; json.load(open('.grok/hooks/project-hooks.json',encoding='utf-8'))" \
      && ok 'project-hooks.json valid JSON' || bad 'project-hooks.json invalid JSON'
  else
    note 'python3 missing; skip JSON parse'
  fi
else
  bad 'project-hooks.json missing'
fi

shs=$(find .grok/hooks/bin -maxdepth 1 -type f -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
[ "${shs:-0}" -ge 6 ] && ok "sh hooks=$shs" || bad "sh hooks low: $shs"

# spawn smoke
if [ -x .grok/hooks/bin/block-pkill.sh ] || [ -f .grok/hooks/bin/block-pkill.sh ]; then
  export GROK_WORKSPACE_ROOT
  GROK_WORKSPACE_ROOT=$(pwd)
  out=$(printf '%s' '{"toolInput":{"command":"echo hi"}}' | bash .grok/hooks/bin/block-pkill.sh 2>/dev/null || true)
  printf '%s' "$out" | grep -q allow && ok 'spawn smoke block-pkill.sh' || bad "spawn smoke failed: $out"
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
