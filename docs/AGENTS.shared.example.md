# 同仓主控已落在 codex-base

Grok + Codex **同仓**时，可执行主控是：

**https://github.com/zylimit/codex-base/blob/main/AGENTS.md**

（根目录 `AGENTS.md` 本体，不是 docs 里的示意文。）

组装：

1. 拷 codex-base 的 `AGENTS.md` + `.codex/` + `.agents/`
2. 再拷本仓 `.grok/`（不要覆盖 `AGENTS.md`）

Skills 权威：`.agents/skills/`。详见 codex-base README「与 Grok 同仓」。

仅 Grok 单用：仍拷本仓 `AGENTS.md` + `.grok/`。
