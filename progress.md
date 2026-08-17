# Project: grok-base

_Last updated: 2026-08-17_

## Pinned

- **单独可用**：只拷 `AGENTS.md` + `.grok/`，无安装、不依赖其它脚手架。
- 布局严格 Grok 官方：rules / skills / agents / roles / personas / hooks / config.toml / sandbox.toml 均在 `.grok/`。
- PowerShell 脚本 ASCII。
- 安全分层（2026-08 官方文档核实）：permission deny（不 fail-open）> hooks（fail-open，显式 deny 才拦）> 纪律；Stop/SubagentStop 官方**可 block**（8 轮上限）——旧「Stop 不能硬拦」表述作废。

## Decisions

- 2026-08-17：hooks OS 分轨定案——源仓 `project-hooks.json` 默认官方相对路径 `bin/*.sh`（Linux 拷贝即用）；`setup.sh` 不把 `.cmd` 装进业务仓，并删除目标仓残留 `.cmd`（对 grok-base 自己 `TARGET==SCRIPT_DIR` 不删源仓 `.cmd`）；Windows 正式项目必须 `setup.ps1` 写 `bin/*.cmd`。hook `.sh` shebang `#!/bin/bash`；no-direct-code-guard 用 lib.sh allow/deny，`subagentType` 放行。`doctor.sh`：JSON 里 `.cmd` 或非 `bin/*.sh` → fail；源仓磁盘 `.cmd` 只 note。跳板 `.cmd` 不进脚手架定案。（理由：Grok spawn 把 command 当可执行文件；源仓默认 `.cmd` 在 Linux 上 644 DOS batch → Permission denied os error 13。用户确认「按照你的思路调整一下脚手架」。）
- 2026-08-16：v2 方向定案——避免 Cursor 化、拒绝 ccb 式厚重，**榨干 Grok Build 原生能力**（rules 目录/嵌套 AGENTS.md/permission/sandbox/LSP/memory/plan 模式/workflows/headless）；兄弟脚手架只吸收工作流经验，架构面不引入。
- 2026-08-16：五性工程落点 = rules 速查（always-on）+ 4 新 Skill（按需）+ 评审 lens + 测试用例 + 发布门禁；架构看护落点 = architect 角色 + ADR + boundaries.txt 机器可查 + arch-check；大库落点 = repo-navigator（CODEMAP/嵌套 AGENTS.md 播种/explore fan-out/LSP/memory）。
- 2026-08-16：workflows(.rhai) 不手写（无公开 schema），指导用户 `/create-workflow` 生成。
- 2026-07-20：纯 Grok 脚手架；工作流可借鉴，架构不跟 foreign harness。
- 2026-07-20：与 codex-base **分开维护、单独运行**（用户确认撤销同仓方案后恢复单独可用表述）。

## TODO

## In Progress

## Done

- 2026-08-17: P2 已落地并经主 Agent 独立验收（CHANGELOG v2.0.4；plugin.json version=2.0.4；用户明确要求 push 后已 commit 并推送 origin/main）。主 Agent 当场重跑：`bash -n` 9 个 sh exit 0；adapters.sh 2 PRESENT / 5 MISSING exit 0、`--strict` exit 1；prune `--dry-run` 只打印 20 天前 corrupt，`--apply` 删 aged corrupt + `.stop-reminder`、保留新 corrupt；zip 含 `password="x"` → release-scan FAIL exit 1，干净目录 PASS exit 0；gate-audit 无 log「no log yet」exit 0，手写 deny 行后 total=1；`deny()` 实写 gate-log.tsv（`GROK_HOOK_NAME=secret-exfil`）；doctor.sh 源仓 passed with warnings(1)（13 个 `.cmd` note）、commands md=6、scripts 含 adapters/prune/release-scan/gate-audit；test-setup.sh PASS（plugin not copied into business repo）；`grok plugin validate plugins/grok-gates` valid、0 hooks，marketplace.json + plugin.json 存在；fitness.sh 源仓 PASS findings=0；adapters.ps1 / release-scan.ps1 非 ASCII 已清零（python bytes>127=0）。（evidence：commit `89d9eefa7910ab56136c01df9f3d2501451f34c3` / 短 `89d9eef` / feat: v2.0.4 native gates (hooks OS split, P0-P2) / https://github.com/zylimit/grok-base.git `23dc2ed..89d9eef  main -> main` / Product-Spec-CHANGELOG.md v2.0.4 / Product-Spec.md / .grok-plugin/marketplace.json / plugins/grok-gates/ / .grok/scripts/{adapters,prune,release-scan,gate-audit}.{sh,ps1} / .grok/commands/{adapters,gate-audit}.md / .grok/hooks/bin/lib.sh）
- 2026-08-17: P1 已落地并经主 Agent 独立验收（CHANGELOG v2.0.3；Product-Spec Skills 18→19；已随 `89d9eef` 推送 origin/main）。workflows：review-changes / nfr-gate / codemap-scan（此前 validate_only 过，已落盘）；commands：/recap /fitness /arch-check /nfr-gate；worktree-parallel + docs/ISOLATION.md；/.worktrees/ 已 gitignore。mark-review 写 `setup.sh<TAB>0cd52c7…` 与 `git hash-object` 一致，改 setup.sh 后 stop-reminder 打出 REVIEW STALE；session-start：二进制 .needs-review 与非法 .fast-mode 均 QUARANTINED 改名为 `*.corrupt-<epoch>`、未重建；doctor：skills=19、workflows=3、commands=4，passed with warnings(1)。（evidence：commit `89d9eef` / Product-Spec-CHANGELOG.md v2.0.3 / Product-Spec.md / .grok/workflows/{review-changes,nfr-gate,codemap-scan}.rhai / .grok/commands/{recap,fitness,arch-check,nfr-gate}.md / docs/ISOLATION.md）
- 2026-08-17: P0 已落地（用户批准后开工；CHANGELOG v2.0.2；已随 `89d9eef` 推送 origin/main）。主 Agent 独立五步闸：fitness 源仓 PASS / 人造 `password=secret123` FAIL；adr-check 无 adr 目录 exit 0；secret-exfil：`cat .env` 与 `sudo cat .env` deny、`echo hi` 与 `.env.example` allow；precompact-keep 打印 progress.md；doctor passed with warnings(1)；test-setup.sh PASS。（evidence：commit `89d9eef` / Product-Spec-CHANGELOG.md v2.0.2）
- 2026-08-17: v2.0.1 脚手架 hooks Linux 原生默认已落地（源仓 JSON 默认 `bin/*.sh`；setup.sh/ps1 分轨；doctor 门禁；Product-Spec 复制面 + CHANGELOG v2.0.1；FRAMEWORK-MANIFEST 已 gen-manifest 刷新）。（evidence：Product-Spec.md / Product-Spec-CHANGELOG.md v2.0.1 / FRAMEWORK-MANIFEST；已随 `89d9eef` 推送 origin/main）
- 2026-08-16: 六仓交叉授粉增量（台账 docs/CROSS-POLLINATION.md）：bug-fixer 增 red-locks 铁律；arch-check 增债务棘轮 `--baseline-write`（五场景实测过）；nfr-gatekeeper 增定档三件套+可度量或不写；修复 pi-base 审计发现的 jq 隐式依赖（lib.sh 增 sed 降级，无 jq 环境实测拦截有效）；明确拒绝 harness runtime 引擎/waiver 替代 Fast Mode 等厚重方案并留痕。
- 2026-08-16: v2 落地：`.grok/rules/`×3、Skills 18（+nfr-gatekeeper/threat-modeler/arch-guardian/repo-navigator）、Agents 8（+architect 三层件）、hooks +3（safe-shell/secrets-guard/subagent-receipt-gate，sh/ps1/cmd）、scripts +4（static-check 修复 code-review 悬空引用/arch-check/codemap/ci-review）、`.grok/config.toml`+`.grok/sandbox.toml`+`.grok/arch/boundaries.txt`；AGENTS.md/README/docs（新增 GROK-NATIVE-MAP）/Spec+CHANGELOG 同步；setup.sh/ps1 hooks JSON 更新。

- 2026-07-20: 单独可用主控/README/docs 定稿并推送。
- 2026-07-20: 抄 cc-base：setup.ps1/sh、doctor、gen-manifest、FRAMEWORK-MANIFEST；Windows hooks 硬化；学习笔记 docs/CC-BASE-LEARNINGS.md；session-rules-banner + no-direct-code-guard；AGENTS 补五步闸/审批三档。

## Risks & Assumptions

## Notes

- 2026-08-17: 用户明确要求 push；已推 https://github.com/zylimit/grok-base.git `23dc2ed..89d9eef  main -> main`（`89d9eef`）。工作区仍留 13 个 `.cmd` 跳板（未入库、未推），本会话继续用。
- 2026-08-17: P2 未在 Windows 实跑 `*.ps1`。
- 2026-08-17: P2 未做 live `grok plugin marketplace add` / `grok plugin install`。
- 2026-08-17: 本机无 unzip；zip 解包走 python3 zipfile（已实测能扫到内容）。
- 2026-08-17: 长会话 `.cmd` 缓存仍在：必须杀 Grok 进程再开，历史红叉不会自行消失。
- 2026-08-17: 用户本轮「Searched 2 patterns, Read 3 files · 1 failed [hooks: 6]」是主 Agent 读错路径 cc-base/scripts/gate-audit.sh（真实在 `.claude/scripts/`），不是新的 hook spawn Permission denied。
- 2026-08-17: P1 未实跑 `/workflow`（仅 `validate_only` 过盘）。
- 2026-08-17: 长会话 `.cmd` 缓存：本会话 pid 自 20:21 未退出，spawn 仍走 `bin/*.cmd`；源仓 `.cmd` 恢复 Windows 644 后 21:01 起 stop/pre_tool_use 再红。工作区已重写 Linux trampoline（不提交、不入库）。亲核 21:39:53 / 21:40:12 `pre_tool_use[0]` 三条全部 success；面板历史红叉不会自行消失。必须杀 Grok 进程再开。
- 2026-08-17: 跳板 `.cmd` 只是长会话缓存的止血，不进源仓/脚手架定案。
- 2026-08-17: 新决策影响 2026-08-16 Done「hooks … sh/ps1/cmd」与 2026-07-20「Windows hooks 硬化」：源仓默认不再以 `.cmd` 为 JSON command；Windows 硬化改由 `setup.ps1` 写入 `bin/*.cmd`。历史条目不改。

## Context Index
