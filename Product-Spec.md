# Grok Base Product Spec

## 产品概述

Grok Base 是面向 **xAI Grok CLI/TUI** 的项目级开发脚手架。配置与扩展点**严格使用 Grok 官方表面**（`AGENTS.md`、`.grok/skills|agents|roles|personas|hooks`、`spawn_subagent`、官方 Hook 事件）。产品开发流程可借鉴其它脚手架的经验，但**不得**引入 Codex/Claude 式第二套目录中枢。

**目标用户**：用 Grok 做软件交付的个人与小团队。  
**核心价值**：**单独可用** + 官方布局 + 拷贝即用；无安装器、无 setup、不与 codex 同仓拼装。

## 复制面

```text
AGENTS.md
.grok/
```

用户操作：拷贝两项到目标项目根 → 打开 Grok → 开始工作。

## 功能需求

- **单独可用 / 零安装**：不依赖其它脚手架；无 setup/install
- 官方 Skills / Agents / Roles / Personas / Hooks 均在 `.grok/`
- 文件夹信任可选；未信任时规则与 Skills 仍可用
- Fast Mode、feedback 为脚手架约定
- 无外部 AI 桥、无 daemon、无默认 auto-push

## 验收标准

- 复制面仅 `AGENTS.md` + `.grok/`，拷后可单独跑通主流程
- 无 setup 脚本；文档主路径是「拷贝 → 打开」
- 不存在对 `.codex/` / 同仓双宿主的运行依赖
