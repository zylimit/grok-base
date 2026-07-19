# Project: grok-base

_Last updated: 2026-07-20_

## Pinned

- **严格 Grok 官方布局**：运行资产只有 `AGENTS.md` + `.grok/`。禁止再引入 `.grok/` 或 `.codex/` 控制面。
- 可借鉴其它脚手架的**工作流**；**配置架构**必须以 Grok user-guide 为准。
- PowerShell 用户脚本保持 ASCII。
- Stop Hook 不能硬阻断；安全靠 PreToolUse deny + 主 Agent 纪律。
- **零安装**：只拷贝 `AGENTS.md` + `.grok/`；trust 是 Grok 可选安全确认，不是安装步骤。

## Decisions

- 2026-07-20：用户要求「必须非常严格按照 grok 官方，只是借鉴 codex」。
- 2026-07-20：删除 `.grok/`；skills/hooks/scripts/feedback 全部归入 `.grok/`。
- 2026-07-20：Hooks 改为官方 `command: "bin/....sh"` 相对路径形式。
- 2026-07-20：复制面从三项改为两项。

## Done

- 2026-07-20: 官方化重构完成（v1.1 布局）。
- 2026-07-20: 文档改为拷贝即用、零安装（v1.1.1）。
- 2026-07-20: 撤销与 codex 同仓双宿主方案；两边分开单独跑。
- 2026-07-20: 文档/验收对齐「grok-base 单独可用」：清 dual 文档、README/AGENTS/Spec 强调拷两项即用。

## Risks

- Windows 无 bash 时 hooks 脚本不跑：依赖 Git Bash / WSL；文档已说明。
