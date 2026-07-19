# Grok Base Architecture

Copy-ready **standalone** Grok scaffold. Deployable surface:

```text
AGENTS.md
.grok/
```

No installer. No dual-stack with Codex. Open the project in Grok after copy.

## Official surfaces

| Surface | Path |
|---|---|
| Project rules | root `AGENTS.md` |
| Skills | `.grok/skills/` |
| Agents | `.grok/agents/*.md` |
| Roles | `.grok/roles/*.toml` |
| Personas | `.grok/personas/*.toml` |
| Hooks | `.grok/hooks/*.json` + `bin/` (paths relative to JSON) |

## Layers

| Layer | Location |
|---|---|
| Orchestration | `AGENTS.md` |
| Agent types / roles / personas | `.grok/agents`, `roles`, `personas` |
| Workflows | `.grok/skills/` |
| Lifecycle hooks | `.grok/hooks/` |
| Fast Mode CLI | `.grok/scripts/` |
| Feedback store | `.grok/feedback/` |

## Control flow

1. Load `AGENTS.md` + discover `.grok/*`.
2. Route via Skills.
3. `spawn_subagent` for role isolation (depth 1).
4. Main agent accepts on evidence.

## Hooks

- Only `PreToolUse` can deny.
- Stop is passive (reminders only).
- Project hooks need folder trust; rules/skills work without it.

## Scaffold conventions (not Grok built-ins)

- `.grok/.fast-mode`, `.grok/.needs-review`, `.grok/feedback/`
