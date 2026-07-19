# Project: grok-base

_Last updated: 2026-07-20_

## Pinned

- **单独可用**：复制面只有 `AGENTS.md` + `.grok/`，不依赖 codex-base、不同仓双宿主。
- **严格 Grok 官方布局**；禁止再引入 `.codex/` 或 `.agents/` 作为主控制面。
- 工作流可借鉴其它脚手架；配置架构以 Grok user-guide 为准。
- 零安装；trust 是可选安全确认，不是安装。
- PowerShell 脚本保持 ASCII；Stop 不能硬拦。

## Decisions

- 2026-07-20：严格 Grok 官方布局；只借鉴 codex 工作流。
- 2026-07-20：Skills/hooks 全部在 `.grok/`；复制面两项。
- 2026-07-20：撤销同仓双宿主；与 codex-base **分开单独跑**。
- 2026-07-20：文档对齐「单独可用 / 拷两项即用」。

## Done

- 2026-07-20: 官方化脚手架 + 零安装文档 + 单独可用清理并推送。

## Risks

- Windows 无 bash 时 hooks 脚本不跑（需 Git Bash / WSL）；未信任时 Hooks 不跑，主流程仍可用。
