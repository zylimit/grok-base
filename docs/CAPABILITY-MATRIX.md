# Capability Matrix

| Capability | Location |
|---|---|
| Product Spec | skill product-spec-builder（含五性初问） |
| NFR / 五性门禁 | nfr-gatekeeper（NFR-Spec + PASS/FAIL 门禁） |
| 威胁建模 / 隐私 DPIA | threat-modeler（Threat-Model.md） |
| 架构 / ADR / 防腐 | arch-guardian + architect（Architecture.md、docs/adr/、boundaries.txt、arch-check） |
| 大库导航（1M LOC） | repo-navigator（CODEMAP、嵌套 AGENTS.md、explore fan-out、LSP、memory） |
| Design | design-brief-builder, design-maker |
| Plan | dev-planner（含架构/NFR/大库前置） |
| Implement | dev-builder + implementer（失控熔断三红线） |
| Bugfix | bug-fixer + implementer（三次失败停机） |
| Review | code-review + code-reviewer（static/arch 闸 + 五性 lens） |
| Test | test-builder + tester（五性用例） |
| Release | release-builder + deployer（五性发布门禁） |
| CI 门禁 | `.grok/scripts/ci-review.sh`（headless 只读评审） |
| 五性/ADR 机器闸 | `.grok/scripts/fitness.*`、`adr-check.*`；hooks `secret-exfil` + `precompact-keep`；默认 `.grok/lsp.json` |
| Feedback / evolution | feedback-writer, evolution-engine |
| Project memory | progress-recorder → progress.md |
| Fast Mode | `.grok/scripts/fast-mode.*` |
| Safety | hooks（PreToolUse/SubagentStop）+ `.grok/config.toml [permission]` + `.grok/sandbox.toml` |
| Slash 门禁 | `.grok/commands/`（recap / fitness / arch-check / nfr-gate / adapters / gate-audit） |
| 适配器/留存/出包/闸审计 | `.grok/scripts/adapters.*`、`prune.*`、`release-scan.*`、`gate-audit.*`（策展探测 / dry-run 销毁 / 产物扫 / deny 计数） |
| 固定编排 | `.grok/workflows/*.rhai`（review-changes / nfr-gate / codemap-scan） |
| 并行隔离 | worktree-parallel + [docs/ISOLATION.md](ISOLATION.md)（hooks ≠ sandbox） |

Counts: 19 Skills, 8 project agents, 1 orchestrator (`AGENTS.md` + 3 rules).
