---
name: grok-gates
description: 当需要跑五性/架构门禁 slash 命令、升级 grok-base 脚手架、或确认 plugin 与项目 hooks 分工时使用。
when-to-use: fitness adr-check nfr-gate recap 门禁 升级 setup.sh plugin hooks 双跑
---

[何时用]
    已装 `grok-gates` plugin、要跑 `/recap` `/fitness` `/arch-check` `/nfr-gate`，或用户问「plugin 和 .grok 谁管 hooks」。
    完整脚手架（规则/Skills/Agents/hooks/权限/沙箱）仍是项目根的 `AGENTS.md` + `.grok/`，用 `./setup.sh`（Windows: `setup.ps1`）注入或升级。本 plugin **只带门禁命令**，**不带 hooks**。

[hooks ≠ plugin]
    项目 hooks 只来自 `.grok/hooks/`（需 `/hooks-trust`）。
    不要把 hooks 放进 plugin：会和项目 `.grok/hooks` **双跑**。
    本 plugin 故意不含 `hooks/`。

[升级脚手架]
    在 grok-base 源仓更新后，对业务仓重跑：

    ```bash
    ./setup.sh /path/to/your-project
    ```

    未改过的框架文件覆盖；改过的落 `*.framework-new`。plugin 在仓根，**不会**被 setup 拷进业务仓。

[跑门禁]
    Linux / macOS：

    ```bash
    bash .grok/scripts/fitness.sh .
    bash .grok/scripts/adr-check.sh .
    ```

    Windows：对应 `.ps1`。贴全文 + exit code。无输出不得 PASS。
    命令正文见 plugin `commands/`（与 `.grok/commands/` 同步）。
