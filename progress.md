# Project: grok-base

_Last updated: 2026-08-16_

## Pinned

- **单独可用**：只拷 `AGENTS.md` + `.grok/`，无安装、不依赖其它脚手架。
- 布局严格 Grok 官方：rules / skills / agents / roles / personas / hooks / config.toml / sandbox.toml 均在 `.grok/`。
- PowerShell 脚本 ASCII。
- 安全分层（2026-08 官方文档核实）：permission deny（不 fail-open）> hooks（fail-open，显式 deny 才拦）> 纪律；Stop/SubagentStop 官方**可 block**（8 轮上限）——旧「Stop 不能硬拦」表述作废。

## Decisions

- 2026-08-16：v2 方向定案——避免 Cursor 化、拒绝 ccb 式厚重，**榨干 Grok Build 原生能力**（rules 目录/嵌套 AGENTS.md/permission/sandbox/LSP/memory/plan 模式/workflows/headless）；兄弟脚手架只吸收工作流经验，架构面不引入。
- 2026-08-16：五性工程落点 = rules 速查（always-on）+ 4 新 Skill（按需）+ 评审 lens + 测试用例 + 发布门禁；架构看护落点 = architect 角色 + ADR + boundaries.txt 机器可查 + arch-check；大库落点 = repo-navigator（CODEMAP/嵌套 AGENTS.md 播种/explore fan-out/LSP/memory）。
- 2026-08-16：workflows(.rhai) 不手写（无公开 schema），指导用户 `/create-workflow` 生成。
- 2026-07-20：纯 Grok 脚手架；工作流可借鉴，架构不跟 foreign harness。
- 2026-07-20：与 codex-base **分开维护、单独运行**（用户确认撤销同仓方案后恢复单独可用表述）。

## Done

- 2026-08-16: 六仓交叉授粉增量（台账 docs/CROSS-POLLINATION.md）：bug-fixer 增 red-locks 铁律；arch-check 增债务棘轮 `--baseline-write`（五场景实测过）；nfr-gatekeeper 增定档三件套+可度量或不写；修复 pi-base 审计发现的 jq 隐式依赖（lib.sh 增 sed 降级，无 jq 环境实测拦截有效）；明确拒绝 harness runtime 引擎/waiver 替代 Fast Mode 等厚重方案并留痕。
- 2026-08-16: v2 落地：`.grok/rules/`×3、Skills 18（+nfr-gatekeeper/threat-modeler/arch-guardian/repo-navigator）、Agents 8（+architect 三层件）、hooks +3（safe-shell/secrets-guard/subagent-receipt-gate，sh/ps1/cmd）、scripts +4（static-check 修复 code-review 悬空引用/arch-check/codemap/ci-review）、`.grok/config.toml`+`.grok/sandbox.toml`+`.grok/arch/boundaries.txt`；AGENTS.md/README/docs（新增 GROK-NATIVE-MAP）/Spec+CHANGELOG 同步；setup.sh/ps1 hooks JSON 更新。

- 2026-07-20: 单独可用主控/README/docs 定稿并推送。
- 2026-07-20: 抄 cc-base：setup.ps1/sh、doctor、gen-manifest、FRAMEWORK-MANIFEST；Windows hooks 硬化；学习笔记 docs/CC-BASE-LEARNINGS.md；session-rules-banner + no-direct-code-guard；AGENTS 补五步闸/审批三档。
