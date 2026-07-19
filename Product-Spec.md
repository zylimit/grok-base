# Grok Base Product Spec

## 产品概述

Grok Base 是面向 **xAI Grok CLI/TUI** 的项目级开发脚手架。配置与扩展点**严格使用 Grok 官方表面**（`AGENTS.md`、`.grok/skills|agents|roles|personas|hooks`、`spawn_subagent`、官方 Hook 事件）。产品开发流程可借鉴其它脚手架的经验，但**不得**引入 Codex/Claude 式第二套目录中枢。

**目标用户**：用 Grok 做软件交付的个人与小团队。  
**核心价值**：官方布局 + **拷贝即用**；无安装器、无 setup。

## 复制面

```text
AGENTS.md
.grok/
```

用户操作：拷贝上述两项到目标项目根目录 → 用 Grok 打开该项目 → 开始工作。

## 功能需求

- **零安装**：不提供、不要求 setup/install/doctor 脚本或全局注册
- 官方 Skills：`.grok/skills/`
- 官方 Agents / Roles / Personas 三层角色
- 官方 Hooks JSON + 相对路径 `bin/*.sh`
- 文件夹信任是 Grok 可选安全确认，不是安装步骤；未信任时规则与 Skills 仍可用
- Fast Mode、feedback、progress 为脚手架约定数据
- PreToolUse 安全拦截；不假装 Stop 可硬阻断
- 无外部 AI 桥、无 daemon、无默认 auto-push

## 验收标准

- 复制面仅 `AGENTS.md` + `.grok/`
- 交付文档主路径是「拷贝 → 打开」，不是「安装 → 配置」
- 无 setup/install 脚本作为交付物
- 不存在 `.agents/` 或 `.codex/` 作为运行依赖
- Hooks 命令符合官方「相对 JSON 路径」写法
