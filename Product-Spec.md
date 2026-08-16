# Grok Base Product Spec

## 产品概述

Grok Base 是面向 xAI Grok Build 的**单独可用**项目脚手架：把需求→架构→计划→开发→检视→测试→发布的工程纪律，固化为 Grok 原生资产（规则/Skills/Agents/Hooks/权限/沙箱）。内建五性工程（韧性/网络安全/功能安全/隐私/可靠性）、架构看护（ADR+边界+防腐）与百万行级大库支持。

## 复制面

```text
AGENTS.md
.grok/
```

拷贝即用；Windows 正式项目可选 `setup.ps1`（hooks 硬化 + manifest 安全升级，非必需）。

## 核心能力

- 规则三层：AGENTS.md + `.grok/rules/`（always-on 速查）+ 18 个按需 Skills
- 八个项目 Agent（三层件：agents/roles/personas），统一派单包/回执 + SubagentStop 回执门禁
- 硬约束三层：`[permission]` deny/ask（不 fail-open）+ hooks（fail-open 显式 deny）+ sandbox（内核级）
- 门禁脚本：static-check / arch-check / codemap / ci-review（headless CI）

## 验收

- 拷两项 → 打开 Grok → `grok inspect` 列出 rules 3 份、18 skills、8 agents、hooks、permission
- 可完成路由：需求（含五性）/ 架构（ADR+边界）/ 计划 / 开发（熔断）/ 检视（五性 lens）/ 测试 / 发布（五性门禁）
- 大库路径：repo-navigator 建 CODEMAP + 嵌套 AGENTS.md + explore fan-out
- 布局 100% Grok 官方 surface（见 docs/GROK-NATIVE-MAP.md），无平行机制
