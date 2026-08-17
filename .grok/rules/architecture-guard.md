# 架构看护（always-on 速查）

- 项目存在 `Architecture.md` / `docs/adr/` 时，任何实现必须先对照；违反声明边界的代码不写、不合并。
- 显著架构决策（新依赖方向、新外部依赖、跨模块契约、数据存储变更）→ 先记 ADR 再动手，用 `arch-guardian` Skill。
- 模块边界规则在 `.grok/arch/boundaries.txt`；改动大或跨模块时跑 `bash .grok/scripts/arch-check.sh`（Windows: `pwsh .grok/scripts/arch-check.ps1`），违规即停。棕地仓库用债务棘轮：存量违规 `--baseline-write` 登记豁免，新增违规零容忍。
- 有 `docs/adr/` 时跑 `bash .grok/scripts/adr-check.sh`：Accepted/Proposed ADR 必须有可解析的 `Enforced-by:`（`manual` 单独不算；幽灵引用失败）。
- 防腐：发现代码绕过声明边界（漂移），不顺手将错就错——标记 ⚡ 漂移，走 arch-guardian 裁决（修代码或改 ADR，二选一）。
- 防失控：单 Task 超出派单 Scope 的改动一律不做；bug 连修 3 次失败停机回到架构层重审（bug-fixer 已有此规）。
