# Grok Base

面向 **xAI Grok** 的**复制即用**脚手架。  
**没有安装器、没有 setup 脚本、没有 daemon。** 拷到目标项目根目录，用 Grok 打开即可。

配置布局遵循 Grok 官方：`AGENTS.md` + `.grok/`。工作流可借鉴其它实践，目录不跟 foreign harness 走。

## 怎么用（仅拷贝）

把下面两项拷到目标项目**根目录**：

```text
AGENTS.md
.grok/
```

PowerShell 示例：

```powershell
Copy-Item -Recurse AGENTS.md, .grok D:\path\to\your-project\
```

然后在该项目里打开 Grok。无需 `npm install`、无需 `setup`、无需注册服务。

Grok 会自动加载：

- 根目录 `AGENTS.md`（项目规则）
- `.grok/skills/`（Skills / 斜杠命令）
- `.grok/agents|roles|personas/`（可派发的 Sub-Agent）
- `.grok/hooks/`（若本机已信任该文件夹；见下方说明）

有同名文件时先合并，不要覆盖项目自己的规则。

## 复制面内容

```text
.grok/
├── skills/       # 官方 Skills 路径
├── agents/       # 官方 Agent 定义
├── roles/        # 官方 roles
├── personas/     # 官方 personas
├── hooks/        # 官方 hooks（*.json + bin/）
├── scripts/      # 可选：Fast Mode 开关
├── feedback/     # 脚手架约定：反馈数据
└── EVOLUTION.md
```

源码仓里的 `docs/`、`Product-Spec*.md`、`progress.md` **不用拷**，那是脚手架自己的维护材料。

## 打开后就能做的事

- 直接说需求 → 走 product-spec / plan / build 工作流  
- `/` 调 Skills（如 `/dev-builder`、`/bug-fixer`）  
- 主 Agent 用 `spawn_subagent` 派 implementer / code-reviewer / tester 等  

### 可选：Fast Mode

```powershell
pwsh .grok/scripts/fast-mode.ps1 on|off|status
```

```bash
bash .grok/scripts/fast-mode.sh on|off|status
```

## 关于 Hooks「信任」

这不是安装步骤。Grok 对**含项目 Hooks 的文件夹**有安全确认（首次 `/hooks-trust` 或 `--trust`）。  

- **不信任**：`AGENTS.md`、Skills、Agents 仍可用，只是项目 Hooks 不跑。  
- **信任**：安全脚本（如拦截 `pkill -f`）才会执行。  

脚手架本身不提供、也不需要任何 install 命令。

## 原则

- 拷贝即交付，零安装  
- 仅 Grok 原生表面  
- 无默认 auto-push、无外部 AI 桥  

## 与 Codex

**分开单独用。** 不要和 codex-base 同仓硬叠两套主控。

- 只用 Grok：拷本仓 `AGENTS.md` + `.grok/`
- 只用 Codex：用 [codex-base](https://github.com/zylimit/codex-base) 的 `AGENTS.md` + `.codex/` + `.agents/`

## 维护者文档

- [架构](docs/ARCHITECTURE.md)
- [能力矩阵](docs/CAPABILITY-MATRIX.md)
- [角色契约](docs/ROLE-CONTRACTS.md)
- [借鉴边界](docs/INSPIRATION-BOUNDARY.md)
