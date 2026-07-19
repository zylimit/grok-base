# Capability Matrix

| Capability | Grok surface | Scaffold piece |
|---|---|---|
| Project rules | `AGENTS.md` | SiteMaster policy |
| Skills | `.grok/skills/` | 14 workflow skills |
| Custom agents | `.grok/agents/` | 7 types |
| Roles / personas | `.grok/roles/`, `.grok/personas/` | capability + behavior |
| Hooks | `.grok/hooks/*.json` | safety + light quality signals |
| Subagent spawn | `spawn_subagent` | role isolation |
| Built-in explore/plan | built-in types | research / planning |
| Worktree isolation | `isolation: worktree` | optional for write tasks |
| Fast Mode | scaffold scripts + state file | quality bypass |
| Feedback / evolution | scaffold data under `.grok/` | learning loop |
| Project memory | `progress.md` at repo root | progress-recorder |

## Counts

- 14 Skills under `.grok/skills/`
- 7 project agent types (+ 3 built-ins available)
- Copy surface: **2** items (`AGENTS.md`, `.grok/`)
