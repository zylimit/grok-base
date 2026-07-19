# Grok Base Architecture

Standalone, copy-ready Grok scaffold.

```text
AGENTS.md
.grok/
```

## Official surfaces

| Surface | Path |
|---|---|
| Rules | root `AGENTS.md` |
| Skills | `.grok/skills/` |
| Agents / roles / personas | `.grok/agents`, `roles`, `personas` |
| Hooks | `.grok/hooks/*.json` + `bin/` |

## Flow

Main agent reads `AGENTS.md` → Skills → `spawn_subagent` (depth 1) → accept on evidence.

## Hooks

Only `PreToolUse` can deny. Stop is passive. Folder trust is optional for hooks.

## Scaffold state (gitignored)

`.grok/.fast-mode`, `.grok/.needs-review`, `.grok/.feedback-signal`, `.grok/.stop-reminder`

## Install surface (cc-base style)

| Asset | Role |
|---|---|
| `setup.ps1` / `setup.sh` | Inject AGENTS.md + .grok; OS-specific hooks; manifest upgrade |
| `.grok/scripts/doctor.*` | Post-install health + spawn smoke |
| `.grok/scripts/gen-manifest.*` | Refresh FRAMEWORK-MANIFEST.txt |
| `.grok/FRAMEWORK-MANIFEST.txt` | Safe upgrade vs user edits |

Preferred install: `pwsh -File setup.ps1 -Target <project>`. See README and [CC-BASE-LEARNINGS.md](./CC-BASE-LEARNINGS.md).
