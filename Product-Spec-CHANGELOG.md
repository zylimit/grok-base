# Product-Spec Changelog

## v2.0.4 — 2026-08-17

- 官方 marketplace `.grok-plugin/` + `plugins/grok-gates`（不含 hooks，避免与项目 hooks 双跑）；setup 不把 marketplace/plugin 拷进业务仓。
- adapters 策展探测；prune 只清 runtime；release-scan 扫产物/归档；deny 写 `gate-log.tsv`，gate-audit 只计数。
- 门禁脚本补 adapters / prune / release-scan / gate-audit；slash 6 个：`/recap` `/fitness` `/arch-check` `/nfr-gate` `/adapters` `/gate-audit`。

## v2.0.3 — 2026-08-17

- P1：官方 workflow 模板 `review-changes` / `nfr-gate` / `codemap-scan`（`validate_only` 冒烟已过）；slash commands `/recap` `/fitness` `/arch-check` `/nfr-gate`。
- worktree-parallel Skill + `docs/ISOLATION.md` 四档（hooks ≠ sandbox）。
- `.needs-review` 改为 `path<TAB>blob指纹`；文件变了 stop-reminder 报 REVIEW STALE。
- 空验证计划 = BLOCKED（nfr / test-builder / 五步闸）。
- session-start 损坏态隔离：坏的 `.needs-review` / `.fast-mode` 改名为 `*.corrupt-<epoch>`，不静默重建。

## v2.0.2 — 2026-08-17

- P0 五性/防腐/防失控机器门禁：`fitness.sh`（密钥字面量/日志PII/空 catch/无界重试/未挂单 TODO）、`adr-check.sh`（ADR `Enforced-by` 对得上真实检查）、`secret-exfil` hook（读/拷/外传 + 剥壳，Fast Mode 不豁免）、`PreCompact` 指针钩子、默认 `.grok/lsp.json`、`test-setup.sh` 装到临时目录自测。
- 接线：nfr/code-review Stage 0/arch-guardian 看护/ci-review 调用 fitness 与 adr-check。

## v2.0.1 — 2026-08-17

- Hooks 安装面改为按 OS 分轨：源仓默认 `project-hooks.json` 使用官方相对路径 `bin/*.sh`（Linux 拷贝即用）；`setup.sh` 不安装、并清除业务仓残留 `.cmd`；Windows 正式项目仍由 `setup.ps1` 写 `bin/*.cmd`。
- 根因：Grok 把 hook `command` 当可执行文件 spawn。源仓若默认 `.cmd`，Linux 上为 644 DOS batch，报 `Permission denied (os error 13)`。
- hook 脚本 shebang 改为 `#!/bin/bash`；`no-direct-code-guard` 对齐 `lib.sh` 的 `allow`/`deny`，子代理带 `subagentType` 放行。
- doctor.sh：JSON 出现 `.cmd` 或非 `bin/*.sh` 即失败；源仓磁盘上的 Windows `.cmd` 只记 note。

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
