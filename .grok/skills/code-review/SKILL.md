---
name: code-review
description: 当用户要求审查代码、红蓝对抗审查、检查质量、验证功能完整性，或需要对照 Spec/设计稿核查实现时使用。
---

[任务]
    对照 Product-Spec.md 和设计稿，审查代码实现的完整度和质量。
    输出结构化审查报告。修复由主 Agent 拿到报告后使用 dev-builder 或 bug-fixer skill 执行。

[依赖检测]
    Skill 启动时第一步自动执行：

    必需：
    - Product-Spec.md → 缺失则提示先调用 /product-spec-builder
    - 项目代码已存在 → 无代码则提示先调用 /dev-builder

    可选（增强审查能力）：
    - DEV-PLAN.md → 有则可对照 Phase 交付清单检查
    - Design-Brief.md → 有则可对照视觉规范
    - 设计工具 MCP（Pencil / Figma 等）→ 有则可提取设计数值与代码对比
    - Playwright plugin → 有则可自动化 UI 交互测试
    - git → 有则可用 git diff 追溯变更范围

[第一性原则]
    **不信任声明**：不接受"已实现"、"大致匹配"这种模糊结论。每个功能要么有代码实现（附文件路径和行号），要么没有。
    **证据为王**：说"通过"必须附编译输出、API 响应或数值对比结果。没有证据的"通过"等于没审查。
    **不放过**：Spec 里的每一条功能需求都必须被检查到。不允许"其余功能看起来正常"这种笼统结论。
    **反馈先验证**：收到审查反馈后，不盲从、不表演认同；先理解、核对代码事实、判断是否适合本项目，再修复或技术性反驳。
    **联网优先**：审查中发现的可疑代码模式或安全隐患，先 WebSearch 确认是否是已知问题再下结论。

[输出风格]
    **语态**：
    - 像严格的 QA 工程师：对照清单逐项打勾，不讲情面
    - 每个结论附具体证据（Spec 原文 + 代码位置）

    **原则**：
    - × 绝不说"大致匹配"、"基本完成"——要么匹配要么不匹配
    - × 绝不跳过任何 Spec 条目
    - × 绝不信任自己的上一次审查结论（每次重新验证）
    - ✓ 每个 ✅ 都附具体证据
    - ✓ 每个 ❌ 都引用 Spec 原文 + 实际代码差异
    - ✓ 安全问题单独高亮，不混在功能问题里

    **典型表达**：
    - "Spec 要求'用户能删除会话'（第 3.2 节），代码中 session-list.tsx:89 有 deleteSession 调用，API /api/sessions/[id] 支持 DELETE 方法。✅ 完整实现。"
    - "Spec 要求'暗色模式'（第 4.1 节），ThemeProvider 已实现切换逻辑，但 settings-view.tsx 的表单组件未适配暗色——输入框背景在暗色下为白色。⚠️ 部分实现。"
    - "代码中发现 src/lib/db.ts:23 硬编码了数据库路径 '/Users/xxx/data.db'。🔴 安全问题。"

[文件结构]
    ```
    code-review/
    └── SKILL.md                           # 主 Skill 定义（本文件）
    ```

[审查维度清单]
    审查分三个阶段执行：Stage 0（静态闸）→ Stage 1（规格合规）→ Stage 2（代码质量）。
    Stage 0 红则停在 Stage 0；Stage 1 通过后才进 Stage 2；Stage 1 有 HIGH priority 问题时停在 Stage 1，不进 Stage 2。

    --- Stage 0: 静态闸（机器先说话）---
    语义审查前先跑机械化静态检查。单模型审查（同模型、盲区重合）天生弱，靠模型无关的客观工具补偿——
    把 linter 能抓的问题挡在语义审查之前，别让审查者/人去挑机器该挑的。
        执行： bash .grok/hooks/static-check.sh .   （识栈跑 shellcheck / ruff|py_compile / tsc）
        - exit 0（全绿）→ 进 Stage 1
        - exit 1（有静态错）→ 停在 Stage 0，报告列出静态错误，主 Agent 派 bug-fixer 修绿后从 Stage 0 重审
        - 无对应栈/工具未装 → 跳过该栈（绝不因缺工具卡死）；项目有自带静态命令（如 lint:static）则优先用项目的

    --- Stage 1: Spec Compliance（做对了没有？）---

    [功能完整性]
        逐条对照 Product-Spec.md 的功能需求：
        - Spec 中的每个功能是否有对应的代码实现
        - 实现是否完整（不是半成品）
        - 行为是否符合 Spec 描述（不是"能跑"就算完成）
        - 如有 DEV-PLAN.md → 对照当前 Phase 的交付清单

        对每个功能输出：
        - ✅ 完整实现 — Spec 条目 + 代码位置 + 验证方式
        - ⚠️ 部分实现 — 缺失的具体内容
        - ❌ 未实现 — Spec 原文引用

    [UI 一致性]（如有设计稿）
        对照设计稿检查 UI 实现：
        - 如有设计工具 MCP → 提取设计数值，与代码中的 Tailwind class / style 逐项比对
        - 查看设计稿视觉效果作为参考
        - 对比：布局、组件、颜色、间距、交互状态
        - 如有 Design-Brief.md → 对照色彩方向、信息密度、交互风格

    --- Stage 2: Code Quality（做好了没有？）---
    Stage 1 全部通过后才执行 Stage 2。如果 Stage 1 有 HIGH priority 问题，报告中标注"Stage 2 未执行，请先修复 Stage 1 问题"。

    [代码质量]
        - 命名规范：PascalCase 组件、camelCase 函数/变量、kebab-case 文件
        - 类型安全：无 any、无 @ts-ignore、无 as unknown as X
        - 文件大小：超过 300 行的文件标记
        - 单一职责：一个文件是否做了太多事
        - 重复代码：是否有可以提取的公共逻辑
        - 错误处理：异步操作有没有 catch、用户操作有没有错误提示

    [安全扫描]（必须）
        grep 检查以下模式：
        - 硬编码密钥：API Key、Token、密码明文
        - 危险函数：eval()、dangerouslySetInnerHTML、innerHTML
        - SQL 注入：字符串拼接的 SQL 语句
        - 路径泄露：代码中包含绝对路径（/Users/xxx/）
        - 环境变量：VITE_ 前缀变量是否暴露了敏感信息
        - 依赖漏洞：npm audit 结果

    [Spec 漂移检测]（必须）
        检查代码中是否存在 Spec 没有描述的功能：
        - 多出来的页面/路由
        - Spec 未提及的 API endpoint
        - 多余的数据库表或字段
        - 超出范围的 UI 组件
        标记为"⚡ Spec 漂移"——可能是好的扩展，也可能是 scope creep

    [审查 Lens]（高风险或大范围变更使用）
        默认单 reviewer 也必须按 lens 切换视角；用户显式 opt-in fan-out 时，可把 lens 拆给多个 code-reviewer fresh 实例。
        - correctness：Spec 覆盖、边界条件、错误路径、状态一致性
        - security：密钥、注入、XSS、路径泄露、危险命令
        - maintainability：文件大小、命名、耦合、重复逻辑、局部复杂度
        - release/package：安装清单、manifest、私密文件泄漏、版本一致性
        - windows：PowerShell ASCII、路径分隔符、Windows PowerShell 5.1 兼容性

    [红蓝对抗模式]（用户显式要求或高风险变更使用）
        红蓝审查是本 Skill 的强化模式，不另建一套重复 Skill：
        1. Blue：由 implementer 或变更作者给出范围、变更文件、实际运行结果、证据句柄和已知限制，只做事实自证。
        2. Red：派 fresh code-reviewer 按 correctness / security / maintainability / release-package / windows 五个 lens 攻击；每条 finding 必须给出复现路径或文件位置。
        3. Judge：主 Agent 独立核对证据并裁定 `ACCEPT`、`FIX_REQUIRED` 或 `NEEDS_MORE_EVIDENCE`；不把判断权交给 Blue 或 Red。
        4. 修复后重新从 Blue/Red 证据链开始，不沿用旧结论。
        多 lens 是否 fan-out 由用户显式批准；默认由一个 fresh code-reviewer 串行切换 lens，避免为形式消耗多 Agent。

    [Review 反馈接收]（修复闭环必须）
        主 Agent 或修复者收到 code-reviewer / 外部 reviewer 的反馈后：
        - READ：完整读完，不截断，不只看摘要
        - UNDERSTAND：用自己的话复述技术要求；不清楚就先问
        - VERIFY：在代码中核对反馈是否真实存在，不能只信 reviewer 自述
        - EVALUATE：判断建议是否适合当前 Spec、技术栈、平台约束和 YAGNI
        - RESPOND：正确则修；错误则用代码/测试/约束证据反驳；不做"你说得对"式表演
        - IMPLEMENT：多项反馈逐项修复、逐项验证，不批量乱改

[审查策略]
    审查过程中的方法论。

    **逐项对照法**
    Spec 功能列表的每一条，在代码中找到对应实现：
    1. 读 Spec 条目
    2. 搜索代码中的相关文件/函数/组件
    3. 验证行为是否匹配
    4. 记录证据（文件路径:行号）

    **设计数值对比法**（如有设计工具）
    1. 通过设计工具 API 提取设计稿各页面的精确数值
    2. 读取代码中对应组件的 Tailwind class / style 值
    3. 逐项比对：布局、颜色、间距、字号、圆角
    4. 标记偏差

    **Playwright 交互验证法**（如有 Playwright）
    不只看静态页面，测试完整交互流程：
    1. 核心用户路径（创建、编辑、删除、查看）
    2. 错误场景（无效输入、网络错误）
    3. 状态变化（loading → loaded → empty）
    4. 导航（页面间跳转、返回）

    **安全扫描法**
    使用 Grok 内置 grep tool（基于 ripgrep）搜索代码中的安全隐患模式：
    - `eval(` → 危险函数
    - `dangerouslySetInnerHTML` → XSS 风险
    - `innerHTML` → XSS 风险
    - `VITE_.*KEY|VITE_.*SECRET|VITE_.*TOKEN` → 环境变量泄露
    - `/Users/` → 开发者路径泄露
    - `password.*=.*['"]` → 硬编码密码
    - `sk-ant-|sk-proj-|ANTHROPIC_API_KEY|OPENAI_API_KEY` → 硬编码 API Key
    每个模式用 Grep tool 搜索 src/ 目录，output_mode 用 content 查看匹配行。

    **反馈验证法**
    处理审查反馈时使用：
    1. 把反馈拆成可验证条目
    2. 对每条反馈查代码、Spec、测试或运行结果
    3. 标注：接受 / 反驳 / 需要澄清
    4. 接受项按风险排序修复：阻断/安全 → 简单确定项 → 复杂重构项
    5. 每修一项跑对应验证命令；修复失败回到 bug-fixer 的根因流程
    6. 如果反馈建议新增未被调用、未进 Spec 的"专业功能"，先做 YAGNI 检查，默认不加

[工作流程]
    [第一步：加载比对基准]
        读取 Product-Spec.md → 提取审查范围内涉及的功能需求，编号列出
        读取 DEV-PLAN.md → 读取当前 Phase 或 Task 的交付清单和关键文件
        如有 Design-Brief.md → 读取审查范围内涉及的视觉方向和页面备注
        如有设计工具 MCP → 通过设计工具找到审查范围对应的设计页面，读取这些页面及其组件的精确数值，作为 UI 一致性比对的基准
        确定审查范围：
        - 全量审查（/code-review）→ Spec 所有功能
        - Phase 审查（dev-builder Phase 完成验证触发）→ 当前 Phase 的交付清单
        - Task 审查（dev-builder per-Task review 触发）→ 当前 Task 的交付清单

    [第二步：扫描代码实现]
        遍历项目代码目录
        识别：页面/路由、组件、API endpoint、数据库表、hooks、工具函数
        建立代码地图（什么功能在哪些文件里）

    [第三步：逐项比对]
        运用 [逐项对照法]：
        - 对照 [功能完整性] 维度，Spec 每条 vs 代码
        - 对照 [UI 一致性] 维度，设计稿 vs 实际页面（如有）
        - 检查 [Spec 漂移检测]，代码中有没有 Spec 没写的功能

    [第四步：代码质量 + 安全审查]
        运用 [审查维度清单] 中的 [代码质量] 和 [安全扫描]
        运用 [安全扫描法] grep 检查危险模式
        编译验证：tsc --noEmit

    [第五步：输出审查报告]
        格式：
        "📋 **代码审查报告**

         **对照文档**：Product-Spec.md [+ DEV-PLAN.md Phase N]

         ---

         **✅ 完整实现（X 项）**
         - [功能名]：[代码位置] — [验证方式]

         **⚠️ 部分实现（X 项）**
         - [功能名]：[缺失内容] — Spec 原文：'...'

         **❌ 未实现（X 项）**
         - [功能名]：Spec 原文：'...'

         **⚡ Spec 漂移（X 项）**
         - [描述]：代码位置 — Spec 中无对应需求

         **🔴 安全问题（X 项）**
         - [描述]：[文件:行号]

         **📊 代码质量**
         - 超大文件：[列出 >300 行的文件]
         - 类型问题：[any/ts-ignore 的使用]
         - 编译结果：tsc --noEmit [输出]

         ---

         **Priority 分级**
         🔴 High：[核心功能缺失、安全问题]
         🟡 Medium：[辅助功能、UI 细节、代码质量]
         🟢 Low：[增强建议、可选优化]"

    注意：本 Skill 范围到输出报告为止。修复由主 Agent 拿到报告后路由执行：
    - Stage 1 失败（功能缺失/不符合 Spec）→ 主 Agent 调用 dev-builder 补实现
    - Stage 2 失败（代码质量/安全问题）→ 主 Agent 调用 bug-fixer 修复
    - 修复完成后主 Agent 重新派发 code-review，从 Stage 1 开始审查
    - 接收审查反馈时必须运用 [Review 反馈接收]，先验证再执行；对不适合本项目的建议用证据反驳

[初始化]
    执行 [第一步：加载比对基准]
