# Grok Base

纯 **xAI Grok**、复制即用脚手架。单独可用，无需安装器 / setup / daemon。

## 使用

把下面两项拷到目标项目根目录：

```text
AGENTS.md
.grok/
```

```powershell
Copy-Item -Recurse AGENTS.md, .grok D:\path\to\your-project\
```

在该项目中打开 Grok 即可。

- 规则：`AGENTS.md`
- Skills：`.grok/skills/`
- Sub-Agent：`.grok/agents` · `roles` · `personas`
- Hooks：`.grok/hooks/`（项目已信任时）

有同名文件时先合并。

## 结构

```text
grok-base/
├── AGENTS.md
├── .grok/
│   ├── skills/
│   ├── agents/
│   ├── roles/
│   ├── personas/
│   ├── hooks/
│   ├── scripts/
│   ├── feedback/
│   └── EVOLUTION.md
├── docs/                 # 维护文档，不进复制面
├── Product-Spec.md
└── progress.md
```

真正复制面只有 **`AGENTS.md` + `.grok/`**。

## Fast Mode

```powershell
pwsh .grok/scripts/fast-mode.ps1 on|off|status
```

```bash
bash .grok/scripts/fast-mode.sh on|off|status
```

## Hooks（Windows）

Grok 会把 `command` 当成**单个可执行文件路径**去启动。

| 写法 | Windows 结果 |
|---|---|
| `bin/foo.sh` | error **193**（不是有效 Win32 程序） |
| `pwsh -File ...` 整行 | 常失败（整串被当文件名） |
| **`bin/foo.cmd`** | 正常：cmd 再调 PowerShell 脚本 |

本脚手架 hooks 入口为相对路径 **`bin/*.cmd`**（相对 `project-hooks.json`）。  
本机需要 PowerShell（优先 7 的 `pwsh`）。项目 Hooks 首次可能要 `/hooks-trust`，改完 hook 配置后请 **重启 Grok 会话** 或在 Hooks 面板 reload。

## 默认原则

- 单独可用、拷贝即用、零安装  
- Fast Mode / auto-push 默认关  
- Sub-Agent 不嵌套  
- 用户当前指令优先  

维护者文档：[架构](docs/ARCHITECTURE.md) · [能力矩阵](docs/CAPABILITY-MATRIX.md) · [角色契约](docs/ROLE-CONTRACTS.md) · [借鉴边界](docs/INSPIRATION-BOUNDARY.md)
