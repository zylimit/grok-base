# Grok Base

纯 **xAI Grok** 脚手架。推荐用安装脚本注入目标项目（抄 cc-base 作业）；也支持手动拷贝。

## 推荐：安装脚本（Windows）

```powershell
# 在 grok-base 仓库根
pwsh -File setup.ps1 -Target D:\path\to\your-project
```

```powershell
# 装到当前目录
cd D:\path\to\your-project
pwsh -File D:\Code\grok-base\setup.ps1
```

### 安装脚本做什么

| 步骤 | 说明 |
|---|---|
| 复制 `AGENTS.md` + `.grok/` | 跳过运行态与私人 feedback |
| 升级安全 | `FRAMEWORK-MANIFEST`：用户改过的文件不覆盖，落 `.framework-new` |
| **写 Windows hooks** | 生成 hardened `bin/*.cmd` + `project-hooks.json`（避免 error 193 / exit 1） |
| 重置 FEEDBACK-INDEX | 不带私人经验进业务仓 |
| doctor | 装完自检 skills/agents/hooks/spawn |

### Unix / macOS

```bash
./setup.sh /path/to/your-project
```

Unix 会把 hooks 写成 `bash "${GROK_WORKSPACE_ROOT}/.grok/hooks/bin/*.sh"`。

## 快速路径：纯拷贝

```powershell
Copy-Item -Recurse AGENTS.md, .grok D:\path\to\your-project\
```

适合试用。**Windows 正式项目请用 setup.ps1**（hooks 适配是安装器的核心价值，见 cc-base 同款结论）。

## 自检

```powershell
pwsh -File .grok\scripts\doctor.ps1 -Target .
```

```bash
bash .grok/scripts/doctor.sh .
```

## 升级

在 grok-base 源仓更新后，对目标项目**重跑 setup**：

- 未改过的框架文件安全覆盖  
- 改过的 → `*.framework-new`，手工合并  
- 重写当前 OS 的 `project-hooks.json`  

源仓改完框架文件后刷新清单：

```powershell
pwsh -File .grok\scripts\gen-manifest.ps1
```

## 打开 Grok 后

1. `/hooks-trust` 或 `grok --trust`（项目 Hooks）  
2. **重启会话** 或 Hooks 面板 reload  
3. 需要 `pwsh`（PowerShell 7+ 优先）

## 复制面 / 装入内容

```text
target/
├── AGENTS.md
└── .grok/
    ├── skills/ agents/ roles/ personas/
    ├── hooks/          # project-hooks.json + bin/*
    ├── scripts/        # doctor, fast-mode, gen-manifest
    ├── feedback/
    ├── EVOLUTION.md
    └── FRAMEWORK-MANIFEST.txt
```

## Fast Mode

```powershell
pwsh .grok/scripts/fast-mode.ps1 on|off|status
```

## 为什么要安装器

Windows 上 Grok 把 hook `command` 当**单个可执行路径** spawn：

- 直接 `.sh` → Win32 **error 193**  
- 整行 `pwsh -File ...` → 常失败  
- 正确：`*.cmd` 包装 + 真 pwsh 路径 + `!ERRORLEVEL!`  

这些适配适合放在 **setup**，不要每次手工拷完再修。

## 维护者文档

- [架构](docs/ARCHITECTURE.md)
- [能力矩阵](docs/CAPABILITY-MATRIX.md)
- [角色契约](docs/ROLE-CONTRACTS.md)
- [借鉴边界](docs/INSPIRATION-BOUNDARY.md)
