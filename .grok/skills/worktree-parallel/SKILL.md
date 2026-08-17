---
name: worktree-parallel
description: 当并行改同一仓库文件、要 worktree 隔离子代理、或合回隔离树时使用。
---

[任务]
    用 git worktree 或 `spawn_subagent(..., isolation: worktree)` 隔离并行改文件。合回主树后以主树测试为准。

[依赖检测]
    必需：git 仓库。
    可选：`spawn_subagent` 的 `isolation: worktree`。

[第一性原则]
    **不嵌套**：禁止在已有 worktree 里再开 worktree；禁止在 submodule 里再建 worktree。
    **目录约定**：`.worktrees/` 必须已在 `.gitignore`（本仓为 `/.worktrees/`）。未 ignore 先补再开树。
    **主树权威**：worktree 不是权威副本。合回主树后重跑受影响测试。
    **只清自己的**：不删除自己没建的 worktree。

[Step 0]
    1. `git rev-parse --git-dir` 与 `--git-common-dir`：若已在 worktree，停，不要再套一层。
    2. `git rev-parse --show-superproject-working-tree`：在 submodule 里则停。
    3. 确认 `.gitignore` 含 `/.worktrees/`（或项目约定的 worktree 根）。没有就先加。

[工作流程]
    [第一步：开隔离]
        只用以下两种之一：
        - `spawn_subagent(..., isolation: worktree)`（Grok 原生）
        - `git worktree add /.worktrees/<name> -b <branch>`（手工）
        不要复制整仓、不要另 clone 当「隔离」。

    [第二步：改文件]
        每个 worktree / 子代理改互不重叠的路径。路径冲突先停，拆 Scope。

    [第三步：合回]
        合入主树（merge / 用户指定的方式）。合回后在**主树**重跑受影响测试。
        worktree 里绿、主树没跑 = 未验证。

    [第四步：清理]
        只清理本轮自己 `git worktree add` 出来的目录。别人的、用户已有的，不动。

[文件结构]
    ```
    worktree-parallel/
    └── SKILL.md
    ```

[初始化]
    先做 [Step 0]，再开隔离。
