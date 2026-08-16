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
| Feedback / evolution | feedback-writer, evolution-engine |
| Project memory | progress-recorder → progress.md |
| Fast Mode | `.grok/scripts/fast-mode.*` |
| Safety | hooks（PreToolUse/SubagentStop）+ `.grok/config.toml [permission]` + `.grok/sandbox.toml` |

Counts: 18 Skills, 8 project agents, 1 orchestrator (`AGENTS.md` + 3 rules).
