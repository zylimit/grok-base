# Grok Base

纯 **xAI Grok**、复制即用脚手架。  
**没有安装器、没有 setup、没有 daemon。** 拷两项到项目根目录，用 Grok 打开即可。

## 使用

```text
AGENTS.md
.grok/
```

```powershell
Copy-Item -Recurse AGENTS.md, .grok D:\path\to\your-project\
```

然后在该目录打开 Grok。无需 `npm install`、无需注册服务。

Grok 自动加载：

- 根目录 `AGENTS.md`
- `.grok/skills/`（Skills / `/` 命令）
- `.grok/agents` · `roles` · `personas`（Sub-Agent）
- `.grok/hooks/`（项目已信任时）

有同名文件时先合并，不要覆盖项目自有规则。

## 结构

```text
.grok/
├── skills/       # 14 个工作流 Skill
├── agents/       # 7 个 agent 类型
├── roles/
├── personas/
├── hooks/        # project-hooks.json + bin/*.sh
├── scripts/      # fast-mode
├── feedback/
└── EVOLUTION.md
```

源码仓的 `docs/`、`Product-Spec*.md`、`progress.md` **不用拷**。

## Fast Mode（可选）

```powershell
pwsh .grok/scripts/fast-mode.ps1 on|off|status
```

```bash
bash .grok/scripts/fast-mode.sh on|off|status
```

跳过自动测试/检视；**不**跳过安全护栏。

## Hooks「信任」

不是安装步骤。Grok 对含项目 Hooks 的目录可能要求首次确认（`/hooks-trust` 或 `--trust`）。

- 未信任：`AGENTS.md` / Skills / Agents 仍可用，Hooks 不跑  
- 已信任：安全脚本等生效  

## 原则

- 拷贝即交付，零安装  
- 仅 Grok 官方表面（`AGENTS.md` + `.grok/`）  
- 与 codex-base **分开单独用**，不要同仓硬叠  
- 无默认 auto-push、无外部 AI 桥  

## 维护者文档

- [架构](docs/ARCHITECTURE.md)
- [能力矩阵](docs/CAPABILITY-MATRIX.md)
- [角色契约](docs/ROLE-CONTRACTS.md)
- [借鉴边界](docs/INSPIRATION-BOUNDARY.md)
