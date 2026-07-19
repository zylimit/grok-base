---
name: branch-finisher
description: 当用户要求收尾当前分支、合并前整理、处理 worktree/detached HEAD 或结束本轮开发时使用。
---

[任务]
    轻量分支收尾助手。只整理当前 Git 状态、给出安全菜单和必要验证，不引入 CCB daemon、tmux、round-counter、trace-matrix 或多模型编队。

[执行步骤]
    1. 探测环境：`git rev-parse --show-toplevel`、`git status --short --branch`、`git branch --show-current`、`git rev-parse --git-dir`、`git rev-parse --git-common-dir`、`git rev-parse --show-superproject-working-tree`。
    2. 判断形态：
       - 正常分支：显示 ahead/behind、未提交文件、建议的测试卡点。
       - worktree：说明当前 worktree 与 common dir，禁止删除自己未创建的 worktree。
       - detached HEAD：提示先建分支或切回目标分支，不直接提交到悬空状态。
    3. 质量卡点：读取当前仓库 `AGENTS.md` 和项目配置，选择该项目实际定义的验证命令；不要依赖 Grok Base 仓库根目录的维护脚本。Fast Mode 开启时跳过自动测试与检视，但仍保留分支/工作树安全检查。
    4. 收尾菜单：给用户 3 个以内选择：
       - 继续修：列出未过验证和待改文件。
       - 准备合并：列出需要提交的文件、验证证据、目标分支。
       - 暂存/保留：说明 stash 或保留 worktree 的安全步骤。
    5. 保护规则：
       - 未合并分支不删除。
       - worktree 未确认不清理。
       - dirty tree 不切分支、不 rebase、不强推。
       - 不执行 `git reset --hard` / `git clean -fd`，除非用户明确逐字要求。

[完成声明]
    遵守 AGENTS.md 的完成声明五步闸：先确定证明命令，当场新跑，读 exit code 和完整输出，确认输出支持结论，再声明。
