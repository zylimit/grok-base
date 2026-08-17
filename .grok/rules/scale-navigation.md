# 大库纪律（>10 万行 / monorepo，always-on 速查）

- 大库先看 `docs/CODEMAP.md`（模块地图）；没有就用 `repo-navigator` Skill 生成，不要盲目全库 grep。
- 勘察一律派 `explore` 子代理（可多路并行 fan-out），主上下文只收结论；不把大文件整读进主上下文。
- monorepo 各包用嵌套 `AGENTS.md` 声明子树约定（官方原生：深层优先）；新包创建时同步播种。
- 语言服务导航配 `.grok/lsp.json`（脚手架默认 typescript/python/gopls；模板见 repo-navigator）。
- memory **opt-in**（`[memory] enabled` 或 `/memory on`，不强制全局开）：`/remember` 只记 ADR/边界/禁区，不记流水；Phase 收口 `/flush`。
- 上下文预算：定期 `/context` 检查；长会话在阶段收口处主动 `/compact`。
