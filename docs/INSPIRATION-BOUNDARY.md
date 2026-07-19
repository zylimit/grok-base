# Inspiration Boundary (codex-base → grok-base)

This document records **what we borrowed as product ideas** versus **what we refused to copy as architecture**.

## Borrowed (workflow ideas only)

- SiteMaster-style product lifecycle: Spec → Plan → Build → Review → Test → Release
- Role separation: implementer / reviewer / tester / deployer / feedback / evolution / progress
- Unified task brief and result envelope
- Fast Mode as an explicit, expiring quality bypass (safety never bypassed)
- progress.md as project memory; feedback/ as AI-behavior learning
- red-blue adversarial review as a *mode* of code-review, not a second skill tree

## Not borrowed (architecture)

| Foreign pattern | Why rejected for Grok Base |
|---|---|
| `.codex/` config hub | Grok project surface is `.grok/` |
| Single agent TOML with sandbox_mode | Grok uses agents.md + roles.toml + personas.toml |
| `command_windows` dual hook entries | Grok hook JSON has one `command`; scripts live under `hooks/bin` relative to JSON |
| `.grok/` skills+hooks+scripts tree as primary | Official skill root is `.grok/skills/`; hooks are `.grok/hooks/` |
| Blocking Stop gate (`continue:false`) | Grok Stop is passive only |
| systemMessage injection from prompt hooks | Grok passive hooks ignore stdout for control; use files + main-agent rules |
| External AI bridge / daemon | Out of scope |

## Dual-harness projects

When Grok and Codex share one repo:

- Keep official trees side by side: `.grok/` and `.codex/` (+ Codex `.agents/`).
- Use one root `AGENTS.md` written as a **shared control plane** (tool branches inside), not a single-tool monolith.
- Template: [AGENTS.shared.example.md](./AGENTS.shared.example.md).

## Rule of thumb

> If a change makes the tree look more like Codex/Claude and less like `~/.grok` / `.grok` docs, reject it.  
> If a change improves product workflow while staying on official Grok surfaces, accept it.
