# Grok Base Product Spec

## 产品概述

Grok Base 是面向 xAI Grok Build 的**单独可用**项目脚手架：把需求→架构→计划→开发→检视→测试→发布的工程纪律，固化为 Grok 原生资产（规则/Skills/Agents/Hooks/权限/沙箱）。内建五性工程（韧性/网络安全/功能安全/隐私/可靠性）、架构看护（ADR+边界+防腐）与百万行级大库支持。

## 复制面

```text
AGENTS.md
.grok/
```

拷贝即用（Linux/macOS）：源仓 `project-hooks.json` 默认 `bin/*.sh`（相对 JSON，Grok 官方 spawn）。Windows 正式项目必须 `setup.ps1`（把 hooks 写成 hardened `bin/*.cmd`，避免 Win32 error 193）。Unix 安装走 `setup.sh`，不把 `.cmd` 装进业务仓。官方 marketplace（`.grok-plugin/`）与 `plugins/grok-gates` **不会**被 setup 拷进业务仓。

## 核心能力

- 规则三层：AGENTS.md + `.grok/rules/`（always-on 速查）+ 19 个按需 Skills（含 worktree-parallel）
- 八个项目 Agent（三层件：agents/roles/personas），统一派单包/回执 + SubagentStop 回执门禁
- 硬约束三层：`[permission]` deny/ask（不 fail-open）+ hooks（fail-open 显式 deny）+ sandbox（内核级）
- 门禁脚本：static-check / arch-check / fitness / adr-check / codemap / ci-review / test-setup（headless CI）/ adapters / prune / release-scan / gate-audit
- slash 6 个：`/recap` `/fitness` `/arch-check` `/nfr-gate` `/adapters` `/gate-audit`
- 官方 marketplace：`.grok-plugin/` + `plugins/grok-gates`（**不含 hooks**，避免与项目 `.grok/hooks` 双跑）
- adapters 策展探测（PATH 有无，不是接线引擎）
- prune 只清 runtime（默认 dry-run）
- release-scan 扫产物/归档（不是只扫源树）
- deny 写 `.grok/hooks/gate-log.tsv`；gate-audit 只按 hook 计数
- 密钥外传闸：`secret-exfil`（Bash 读/拷/管道外传 + wrapper 剥壳，Fast Mode 不豁免）
- 压缩保活：`PreCompact` 钩子打印三文件/ADR/待审指针
- 默认 LSP 剖面：`.grok/lsp.json`（ts / python / gopls）

## 验收

- 拷两项 → 打开 Grok → `grok inspect` 列出 rules 3 份、19 skills、8 agents、hooks、permission
- 可完成路由：需求（含五性）/ 架构（ADR+边界）/ 计划 / 开发（熔断）/ 检视（五性 lens）/ 测试 / 发布（五性门禁）
- 大库路径：repo-navigator 建 CODEMAP + 嵌套 AGENTS.md + explore fan-out
- 布局 100% Grok 官方 surface（见 docs/GROK-NATIVE-MAP.md），无平行机制
