# Cross-Pollination 台账

跨仓吸收/拒绝双向留痕。原则（见 INSPIRATION-BOUNDARY.md）：**只吸收工作流经验，架构面 100% Grok 原生**。

## 2026-08-16 六仓并行分析（codex/cc/pi/cursor/agy/opencode-base）

### 已吸收

| 来源 | 条目 | grok-base 落点 |
|---|---|---|
| cc/codex/opencode | red-locks-the-bug（缺陷先固化为失败测试再修） | bug-fixer 第一性原则 |
| pi/cursor/cc/codex/agy | 架构债务棘轮（存量豁免、新增零容忍） | arch-check.sh/.ps1 `--baseline-write` |
| pi/cc/opencode | dfx 定档追问三件套（坏1小时/上新闻/谁半夜修）+「可度量或不写」 | nfr-gatekeeper |
| pi（审计发现） | jq 隐式依赖导致 guard 静默失效 | lib.sh tool_file_paths 增 sed 降级 |
| cc（早前已吸收） | setup/doctor/gen-manifest/FRAMEWORK-MANIFEST | 见 CC-BASE-LEARNINGS.md |
| 多仓共识（v2 已内建同类） | 五性六档思想、ADR 执法引用、无占位符、反合理化清单、统一派单/回执 | rules/ + 各 Skill（轻量文本形态） |

### 明确拒绝（含理由）

| 条目 | 来源 | 拒绝理由 |
|---|---|---|
| 独立 harness runtime（module-catalog/impact/context-pack/receipt 哈希链引擎，3k–6k 行 JS/TS） | codex/cursor/pi/cc/opencode | 用户定向：避免厚重外挂；Grok 原生已有对位能力（plan 模式、permission、sandbox、workflows、explore fan-out、嵌套 AGENTS.md、memory），大库走 repo-navigator 原生打法 |
| verification-matrix / attributes 接线审计引擎 | 同上 | 同上；五性证据化以 NFR-Spec 条目 + nfr-gatekeeper 门禁模式（人机共审）承载 |
| waiver 机制替代 Fast Mode | cursor | Fast Mode 是本仓既有用户决策；NFR 豁免已要求留名+理由，安全护栏不受 Fast Mode 豁免 |
| shell hook 全面 TS 化 | pi | Grok hooks 官方载体即命令脚本；保持 sh/ps1/cmd 三平台 |
| PreCompact/agent memory/异步 verify 等宿主特性 | cc | 依赖 Claude Code 专有事件面；Grok 对应能力（PreCompact 事件存在但暂无需求）待有真实场景再启用 |

### 待观察（有价值但暂缓）

- gate-audit 死闸淘汰（闸门拦截战绩统计）：当前 hooks 数量少，成本>收益；hooks 超过 ~10 个时再评估。
- 框架自测试套件（opencode 72 例/cursor CI 矩阵）：当前以 doctor + 手工五步闸覆盖；资产继续增长时补。
