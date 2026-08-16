---
name: repo-navigator
description: 当项目超过 10 万行、是 monorepo、需要生成/维护代码地图（CODEMAP）、配置 LSP 导航、播种嵌套 AGENTS.md，或在大库中定位代码/控制上下文时使用。
when-to-use: 大型代码库、monorepo、百万行、代码地图、CODEMAP、找不到代码、上下文爆炸、LSP、嵌套 AGENTS.md
---

[任务]
    让 Grok 在 100 万行级代码库里高效工作：建立并维护 docs/CODEMAP.md，播种子树 AGENTS.md，配置 LSP，并给出大库勘察/开发的标准打法。全程只用 Grok 原生机制（explore 子代理、嵌套规则、LSP、memory、worktree）。

[依赖检测]
    - git 仓库 → 用 `git ls-files` 统计（快且尊重 ignore）；非 git 则退化为 find
    - `.grok/scripts/codemap.sh` 存在 → 用脚本生成统计骨架
    - 无前置文档要求（本 Skill 常是大库接手的第一步）

[第一性原则]
    **地图先于探险**：接手大库第一件事是建 CODEMAP，不是逐目录乱逛。地图一页纸讲清"什么在哪、谁拥有、从哪进"。
    **主上下文是稀缺资源**：勘察派 explore 子代理（各带独立上下文），主会话只收结论。永不把大文件整读进主上下文。
    **规则跟着目录走**：官方嵌套 AGENTS.md 深层优先——每个模块的约定写在模块自己的 AGENTS.md 里（3~10 行），根 AGENTS.md 只留全局规则。
    **记忆外置**：跨会话要复用的架构事实进 memory（`/remember` / `/flush`）或 CODEMAP，不靠会话记忆。

[标准打法]
    [打法一：建图（首次接手大库）]
        1. `bash .grok/scripts/codemap.sh`（Windows: `pwsh .grok/scripts/codemap.ps1`）
           → 得到目录级 LOC/语言/文件数统计骨架
        2. 按骨架并行派 3~6 个 explore 子代理，每个负责一片：
           派单必含——Goal（回答该片区：职责/入口/关键类型/对外接口）、Scope（目录列表）、
           Verification（N/A）、要求回执 ≤400 字
        3. 汇总进 templates/codemap-template.md 结构，落 docs/CODEMAP.md
        4. 顺手把明确的模块约定播种为该目录的 AGENTS.md（见打法三）

    [打法二：定位（在大库找实现/改动点）]
        1. 先查 CODEMAP 锁定候选片区（没有 CODEMAP → 先花 10 分钟走打法一的精简版）
        2. 单片区内：grep 具体符号 → LSP 跳定义/找引用（配置见打法四）
        3. 跨片区疑问 → explore 子代理带问题去查，主会话不跟进细节
        4. 找到后把"入口 → 关键文件"路径记回 CODEMAP 的对应模块行

    [打法三：播种嵌套 AGENTS.md（monorepo 必做）]
        每个包/模块根放一个 3~10 行 AGENTS.md，只写该子树独有的：
        技术栈与版本、构建/测试命令、本包禁忌（如"禁止 import 其他包内部路径"）
        官方语义：深层文件后加载、冲突时生效；被 gitignore 的文件不加载。
        根 AGENTS.md 保持全局纪律，绝不复制各包细节（上下文经济）。

    [打法四：LSP 导航]
        项目根放 `.grok/lsp.json`（模板：templates/lsp-example.json，改成项目实际语言服务）。
        被动诊断有配置即生效；主动 lsp 工具（goToDefinition/findReferences/workspaceSymbol）
        需用户侧开启：`GROK_LSP_TOOLS=1` 或 `~/.grok/config.toml` 设 `[features] lsp_tools = true`。
        生效后优先用 LSP 跳转替代全库 grep；同工作区子代理复用父会话的 LSP 运行时，无额外成本。
        注意：repo 级 LSP 与 hooks 同属文件夹信任（`/hooks-trust`）。

    [打法五：大库开发纪律]
        - 改动前用 `git diff --stat` 预估波及面；单 Task 波及 >20 文件 → 回 dev-planner 拆分
        - 多人/多任务并行 → 子代理用 `isolation: worktree`，改动隔离后再合回
        - 长会话在 Phase 收口处 `/flush` 沉淀 + `/compact` 收上下文；随时 `/context` 看水位
        - 大规模机械改造（改 import、重命名）优先脚本化（sed/comby/codemod）再人查抽样，不逐文件手改

[CODEMAP 维护规则]
    - CODEMAP 是活文档：每次显著结构变更（新模块/搬迁/删除）随手更新对应行
    - 只到模块粒度，不列文件清单（文件会腐烂，模块稳定）
    - 每模块一行：路径 | 职责 | 入口 | 负责人/域 | 备注

[文件结构]
    ```
    repo-navigator/
    ├── SKILL.md
    └── templates/
        ├── codemap-template.md
        └── lsp-example.json
    ```

[初始化]
    检查 docs/CODEMAP.md 是否存在：无 → 打法一；有 → 按用户意图选打法二~五。
