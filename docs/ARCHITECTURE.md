# Grok Base Architecture

Standalone, copy-ready Grok scaffold.

```text
AGENTS.md
.grok/
```

## Official surfaces

| Surface | Path |
|---|---|
| Rules | root `AGENTS.md` + `.grok/rules/*.md`（五性/架构/大库速查，always-on） |
| Skills | `.grok/skills/` (19) |
| Agents / roles / personas | `.grok/agents`, `roles`, `personas` (8 × 3 层) |
| Hooks | `.grok/hooks/*.json` + `bin/`（sh/ps1/cmd 三平台） |
| Permission | `.grok/config.toml [permission]`（deny 密钥 / ask push·publish） |
| Sandbox | `.grok/sandbox.toml`（grok-secure / grok-review）；档位 [ISOLATION.md](ISOLATION.md) |
| Slash commands | `.grok/commands/*.md`（recap / fitness / arch-check / nfr-gate / adapters / gate-audit） |
| Workflows | `.grok/workflows/*.rhai`（review-changes / nfr-gate / codemap-scan） |
| Arch rules | `.grok/arch/boundaries.txt` + `scripts/arch-check.*` |
| Gate scripts | `scripts/static-check.*`、`arch-check.*`、`fitness.*`、`adr-check.*`、`codemap.*`、`ci-review.sh`、`test-setup.sh`、`adapters.*`、`prune.*`、`release-scan.*`、`gate-audit.*` |

## Flow

Main agent reads `AGENTS.md`+rules → Skills → `spawn_subagent`（depth 1，八角色）→ accept on evidence（五步闸）。 
质量链：Spec（含五性初问）→ NFR-Spec/Threat-Model → Architecture+ADR+boundaries → DEV-PLAN → 实现（熔断红线）→ 审查（五性 lens + static/arch 闸）→ 测试（五性用例）→ 发布（五性门禁）。

## Hooks

- `PreToolUse` 可 deny（safe-shell / secret-exfil / block-pkill / secrets-guard / no-direct-code-guard / pre-commit-check）
- `PreCompact` 被动（precompact-keep：progress/Spec/ADR/待审指针，不 block）
- `SubagentStop` 可 block 一次（subagent-receipt-gate：统一回执缺失时拦停）
- `Stop` 官方支持 block（8 轮上限），本脚手架仅用作被动提醒（stop-reminder）
- 全部 fail-open：硬约束由 permission deny + sandbox 承担

## Scaffold state (gitignored)

`.grok/.fast-mode`, `.grok/.needs-review`, `.grok/.feedback-signal`, `.grok/.stop-reminder`, `.grok/hooks/gate-log.tsv`

## Install surface (cc-base style)

| Asset | Role |
|---|---|
| `setup.ps1` / `setup.sh` | Inject AGENTS.md + .grok; OS-specific hooks; manifest upgrade |
| `.grok/scripts/doctor.*` | Post-install health + spawn smoke |
| `.grok/scripts/gen-manifest.*` | Refresh FRAMEWORK-MANIFEST.txt |
| `.grok/FRAMEWORK-MANIFEST.txt` | Safe upgrade vs user edits |

Preferred install: `pwsh -File setup.ps1 -Target <project>`. See README, [CC-BASE-LEARNINGS.md](./CC-BASE-LEARNINGS.md), [GROK-NATIVE-MAP.md](./GROK-NATIVE-MAP.md).
