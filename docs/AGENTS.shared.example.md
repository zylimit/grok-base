# 已撤销同仓方案

`codex-base` 与 `grok-base` **分开单独使用**，不再维护双宿主共用主控。

| 脚手架 | 复制面 |
|---|---|
| **codex-base** | `AGENTS.md` + `.codex/` + `.agents/` |
| **grok-base** | `AGENTS.md` + `.grok/` |

不要在同一业务项目里叠两套主控硬共用。需要换工具时换脚手架，不要混装。
