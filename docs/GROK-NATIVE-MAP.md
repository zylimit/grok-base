# Grok Build 原生能力 ↔ grok-base 资产映射

对照官方文档（docs.x.ai/build + 仓内 user-guide，2026-08 核实）。原则：**架构 100% 走官方 surface，不造平行机制**。

| 官方能力 | 官方载体 | grok-base 落点 |
|---|---|---|
| 项目规则 | `AGENTS.md`（无字符截断，仍需精简） | 根 AGENTS.md（主控编排） |
| 模块化规则目录 | `.grok/rules/*.md`（always-on，字母序） | quality-attributes / architecture-guard / scale-navigation 三份速查 |
| 嵌套规则 | 子目录 AGENTS.md（深层优先） | repo-navigator「播种法」（monorepo 每包 3–10 行） |
| Skills | `.grok/skills/<n>/SKILL.md`（frontmatter：name/description/when-to-use…） | 19 个 Skill；description 皆含触发语 |
| Agent 定义 | `.grok/agents/*.md`（frontmatter + prompt） | 8 个项目 Agent |
| Roles / Personas | `.grok/roles|personas/*.toml`（capability/model 默认 + 行为覆盖层） | 每 Agent 三层件；persona 内含派单/回执契约 |
| 子代理 | `spawn_subagent`（capability_mode / isolation:worktree / background / resume_from；depth=1） | 核心纪律 2/3 条 |
| 权限规则 | 项目 `.grok/config.toml [permission]`（deny>ask>allow；always-approve 下 deny+段级 ask 仍生效） | 密钥 deny + push/publish ask 底座 |
| 沙箱 | `.grok/sandbox.toml` 自定义 profile（Landlock/Seatbelt，内核级） | grok-secure / grok-review 两档 |
| Hooks | `.grok/hooks/*.json`；PreToolUse 可 deny；Stop/SubagentStop 可 block（8 轮上限）；一律 fail-open | safe-shell、secret-exfil、block-pkill、secrets-guard、no-direct-code-guard、subagent-receipt-gate、precompact-keep 等 |
| LSP | `.grok/lsp.json`（被动诊断 + lsp 工具） | 脚手架默认 `.grok/lsp.json`（ts/python/gopls）；模板 lsp-example.json |
| Plan 模式 | `/plan`，方案批准前锁编辑 | 核心纪律 10 |
| 多选问答 | `ask_user_question` | 需求/方案追问用 |
| Memory | `[memory]`、`/remember`、`/flush`、`/dream` | 大库纪律：架构事实沉淀 |
| Workflows | `.grok/workflows/*.rhai`（`/create-workflow` 交互生成） | 仓内：review-changes / nfr-gate / codemap-scan |
| Slash commands | `.grok/commands/*.md` | recap / fitness / arch-check / nfr-gate / adapters / gate-audit |
| 适配器策展 / 留存 / 出包扫 / 闸审计 | 无官方平行机制（本地脚本） | adapters / prune / release-scan / gate-audit |
| Headless | `grok -p --allow/--deny --output-format json` | scripts/ci-review.sh CI 门禁模板 |
| 体检 | `grok inspect (--json)` | README 自检步骤 |
| 兼容面 | 读 .claude/.cursor 资产（可关） | 不依赖；纯 .grok |

## 已知边界（诚实清单）

- hooks fail-open：安全兜底靠 permission deny（不 fail-open）+ sandbox（内核）双层。
- SubagentStop 回执门禁只拦一次（stopHookActive 防循环），是提醒性门禁不是硬闸。
- sandbox 在 Windows 无内核支持；Windows 以 hooks + permission 为主。
- `.grok/config.toml` 项目层只加载 permission/MCP/plugins；shell_environment_policy 等须用户级配置。
