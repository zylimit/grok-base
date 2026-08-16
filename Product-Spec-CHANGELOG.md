# Product-Spec Changelog

## v2.0.0 — 2026-08-16

- 定位升级：从「工作流脚手架」到「工程质量 harness」——内建五性工程（韧性/Security/Safety/隐私/可靠性）、架构看护（ADR/边界/防腐/arch-check）、百万行级大库支持（CODEMAP/嵌套 AGENTS.md/LSP/explore fan-out）。
- 原生能力对齐（docs.x.ai/build 2026-08 核实）：新增 `.grok/rules/`（3 份 always-on 速查）、`.grok/config.toml [permission]`、`.grok/sandbox.toml`、SubagentStop 回执门禁；修正「Stop 不能硬拦」过时假设（官方已支持 Stop/SubagentStop block，8 轮上限）。
- 新 Skills ×4：nfr-gatekeeper、threat-modeler、arch-guardian、repo-navigator（合计 18）；新角色 architect（合计 8）。
- 新 hooks ×3：safe-shell、secrets-guard、subagent-receipt-gate；新门禁脚本 ×4：static-check（修复 code-review 悬空引用）、arch-check、codemap、ci-review。
- 验收改为 `grok inspect` 可见性 + 全链路路由 + 大库路径。

## v1.2.0 — 2026-07-20

- 恢复为**纯 Grok 单独可用**：复制面 `AGENTS.md` + `.grok/`，去掉同仓/双宿主叙事。

## v1.1.x — 2026-07-20

- 官方布局迁移与拷贝即用文档。
