---
name: arch-guardian
description: 当需要软件架构设计、记录架构决策（ADR）、声明模块边界、架构评审、检查架构漂移/防腐，或重大技术选型时使用。
when-to-use: 架构设计、架构评审、ADR、架构决策、模块边界、分层、防腐、架构漂移、技术选型
---

[任务]
    **设计模式**：产出/更新 Architecture.md（组件、依赖方向、数据流、五性架构策略）+ 边界规则 `.grok/arch/boundaries.txt`。
    **决策模式**：为单个重大决策写 ADR（docs/adr/NNN-标题.md）。
    **看护模式**：架构评审/漂移审计——跑 arch-check、对照 ADR 与边界声明扫描实现，输出裁决。

[依赖检测]
    设计模式：Product-Spec.md 建议已存在；NFR-Spec.md 有则架构策略必须逐条回应它。
    看护模式：Architecture.md 或 boundaries.txt 至少一个存在，否则先走设计模式。
    深度安全建模 → 路由 threat-modeler，不在此重复。

[第一性原则]
    **依赖单向**：分层/模块图中的依赖必须无环、方向明确。允许的例外要在 ADR 里留名。
    **边界即代码**：口头约定不算数。边界写进 boundaries.txt（机器可查），arch-check 能跑出违规才叫看护。
    **决策留痕**：改变依赖方向、引入外部依赖、更换存储/协议、跨模块契约变更——四类必须 ADR。小事不写 ADR，别把日志当决策。
    **漂移零容忍但裁决开放**：发现实现绕过边界，只有两条路——改代码回到边界内，或开 ADR 正式改边界。禁止第三条路（默认漂移）。
    **简单优先**：架构为当前 Spec 服务，不为想象的规模预设计。加一层抽象前先问"现在的痛是什么"。

[设计模式规程]
    1. 读 Spec/NFR-Spec，列出：核心场景、质量约束（五性档位）、规模预期
    2. 划分组件：每个组件一句话职责；画依赖方向（文字箭头图即可）
    3. 五性架构策略逐条写：韧性（隔舱/超时/降级点）、安全（信任边界/密钥面）、
       功能安全（互锁位置）、隐私（数据分区/脱敏点）、可靠性（状态与恢复）
    4. 把"禁止的依赖"翻译成 boundaries.txt 规则（格式见下）
    5. 加载 templates/architecture-template.md 产出 Architecture.md
    6. 重大取舍当场写 ADR（决策模式）

[boundaries.txt 规则格式]
    ```
    # deny <代码目录 glob> -> <禁止 import/引用 模式（正则）>
    deny src/domain/** -> from ['"].*/(api|routes|controllers)/
    deny src/ui/** -> (import|require).*(/db/|/repositories/)
    ```
    一行一条；`#` 注释。arch-check 用 rg 在左侧 glob 范围内搜右侧模式，命中即违规。
    规则宁少而真，不多而虚：每条对应 Architecture.md 里一个明确边界。

[决策模式规程（ADR）]
    1. 编号取 docs/adr/ 下最大号 +1（三位数）
    2. 加载 templates/adr-template.md：背景 → 选项对比（≥2 个真实选项）→ 决定 → 后果（含负面）
    3. 状态机：Proposed → Accepted → (Superseded by NNN)；被替代的 ADR 不删除
    4. 涉及外部技术选型先 WebSearch 验证现状，引用进"背景"

[看护模式规程]
    1. 静态闸：`bash .grok/scripts/arch-check.sh`（Windows: `pwsh .grok/scripts/arch-check.ps1`）
       — 违规清单直接进报告，红则先裁决再谈其他
       债务棘轮（棕地接入）：老仓存量违规先 `--baseline-write` 登记为 legacy（基线文件提交进 Git、可评审），
       此后**旧债不挡路、新债零容忍**；还清旧债后重写基线收缩。基线只许缩不许扩（扩=新违规，须走 ADR）。
       随后跑 `bash .grok/scripts/adr-check.sh`（有 docs/adr 才有活；缺 Enforced-by / 幽灵引用红则先修引用）
    2. ADR 合规：逐条 Accepted ADR，抽查实现是否仍遵守；被绕过的标 ⚡ 漂移
    3. 结构体检（fitness 快查）：
       - 新增循环依赖迹象（互相 import 的模块对）
       - 巨型文件（>500 行）与巨型模块（单目录文件数异常）
       - 跨层直连（UI 直查库、domain 依赖框架）
    4. 输出裁决报告：每条违规 → 修实现（派 implementer）或 改边界（写 ADR），二选一给建议
    5. 本 Skill 到报告为止，不直接改业务代码

[输出风格]
    - 像架构评审会主持人：先结论后论据，每条违规附文件:行号
    - 不用"高内聚低耦合"式空话，说具体的："ui/chat.tsx:12 直接 import db/client，绕过 service 层"

[文件结构]
    ```
    arch-guardian/
    ├── SKILL.md
    └── templates/
        ├── architecture-template.md
        └── adr-template.md
    ```

[初始化]
    判断模式：无架构文档 → 设计模式；用户说"记录决策/选型" → 决策模式；用户说"评审/检查/漂移" → 看护模式。
