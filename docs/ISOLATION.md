# Isolation tiers

hooks ≠ sandbox。hooks 是进程内策略（fail-open，要拦必须显式 deny）；sandbox 是内核强制（会话内不可逆）。不要把「挂了 hook」说成「已隔离」。

| 档 | 是什么 | 本仓有没有 | 诚实边界 |
|---|---|---|---|
| **L0 共享工作区** | 同一工作树、同一 index。hooks 只观察/按规则 deny 工具。 | 默认。`.grok/hooks/` | **不是隔离**。hook 挂了仍共享文件；hooks fail-open，漏拦就落地。 |
| **L1 `isolation: worktree`** | 另开 git worktree（或 `git worktree add`）。对象库共享，工作区分开。 | `spawn_subagent(..., isolation: worktree)`；规程见 skill `worktree-parallel` | 不是容器、不是内核沙箱。合回后以**主树**测试为准。禁止嵌套 worktree / 在 submodule 里再建。 |
| **L2 工具容器** | docker / podman 等把工具关进容器。 | **用户自备。本仓不提供镜像或编排。** | 没有用户容器就没有 L2。不要把 worktree 或 hook 说成容器。 |
| **L3 内核沙箱** | `grok --sandbox grok-review\|strict`（Landlock / Seatbelt）。 | 项目 profile：`.grok/sandbox.toml`（另有 `grok-secure`）。Windows 无内核沙箱。 | 会话级、不可逆。hooks 仍不是这一层。 |

选用：日常开发 L0；并行改文件 L1；不信任工具链才上 L2/L3。
