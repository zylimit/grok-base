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
