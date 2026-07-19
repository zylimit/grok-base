# Grok Base Architecture

Grok Base is a **Grok-native** project scaffold. Deployable surface:

```text
AGENTS.md
.grok/
```

Everything runtime-related lives under the official project directory `.grok/` plus root `AGENTS.md`. There is no `.codex/`, no `.agents/` control plane, and no foreign harness config.

## Official Grok surfaces used

| Surface | Path | Guide |
|---|---|---|
| Project rules | `AGENTS.md` | user-guide/12-project-rules |
| Skills | `.grok/skills/` | user-guide/08-skills |
| Agents | `.grok/agents/*.md` | user-guide/16-subagents |
| Roles | `.grok/roles/*.toml` | user-guide/16-subagents |
| Personas | `.grok/personas/*.toml` | user-guide/16-subagents |
| Hooks | `.grok/hooks/*.json` | user-guide/10-hooks |
| Optional project config | `.grok/config.toml` | user-guide/05-configuration (MCP/plugins/permissions only) |

## Layers

| Layer | Location | Responsibility |
|---|---|---|
| Orchestration | `AGENTS.md` | SiteMaster role, routing, Fast Mode policy, safety |
| Agent types | `.grok/agents/` | Spawnable `subagent_type` definitions |
| Role defaults | `.grok/roles/` | capability_mode / isolation defaults |
| Personas | `.grok/personas/` | Behavioral overlay for subagents |
| Workflows | `.grok/skills/` | Product lifecycle procedures |
| Lifecycle automation | `.grok/hooks/` | Official hook events + `bin/` scripts (paths relative to JSON) |
| Scaffold extras | `.grok/scripts/`, `.grok/feedback/` | Fast Mode CLI; feedback store (not Grok built-ins) |

## Control flow

1. Grok loads `AGENTS.md` and discovers `.grok/skills`, agents, roles, personas, hooks.
2. Main agent routes via Skills.
3. Isolated work uses `spawn_subagent` (depth 1 built-in).
4. Child returns status + evidence; main agent accepts.

## Hooks (official semantics)

- Registered only via `.grok/hooks/*.json`.
- `command` is relative to the JSON file (e.g. `bin/session-start.sh`).
- **Only `PreToolUse` can deny** (`{"decision":"deny","reason":"..."}`).
- `Stop` / `SessionStart` / `UserPromptSubmit` are passive.
- Project hooks may require Grok folder trust (`/hooks-trust` or `--trust`) — this is a **security prompt**, not a scaffold install step. Rules and Skills work without it.
- Runner injects `GROK_WORKSPACE_ROOT`, `GROK_SESSION_ID`, `GROK_HOOK_EVENT`, etc.

## Delivery model

Copy `AGENTS.md` + `.grok/` into a project root. No installer, no setup script, no global registration.

## Scaffold conventions (not Grok built-ins)

These are product choices implemented *on top of* official surfaces:

- Fast Mode state: `.grok/.fast-mode`
- Review registry: `.grok/.needs-review`
- Feedback store: `.grok/feedback/`
- Evolution notes: `.grok/EVOLUTION.md`
- User CLI: `.grok/scripts/fast-mode.{sh,ps1}`

## Explicit non-goals

- Codex `.codex/config.toml` / `command_windows`
- Claude `.claude/settings.json` as primary config
- `.grok/` as a second control plane
- External model bridges, daemon, tmux, CCB
- Pretending Stop hooks can hard-block a turn
