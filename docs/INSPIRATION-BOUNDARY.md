# Inspiration Boundary

Grok Base **单独可用**。复制面只有：

```text
AGENTS.md
.grok/
```

## Borrowed as workflow ideas only

Product lifecycle, role separation, task brief / result envelope, Fast Mode semantics, progress vs feedback — may learn from other scaffolds (e.g. codex-base).

## Not borrowed as architecture

| Foreign pattern | Why rejected |
|---|---|
| `.codex/` hub | Grok surface is `.grok/` |
| `.agents/` as primary control plane | Official skills/hooks live under `.grok/` |
| Dual-host shared AGENTS with Codex | Scaffolds stay **separate**; one project uses one harness |
| Claude `.claude/CLAUDE.md` as only main brief | Grok main control is root `AGENTS.md` |
| Installer / daemon / external AI bridge | Out of scope |

## Rule of thumb

> Workflow may be inspired elsewhere. Runtime layout must match Grok official docs. Run alone: copy two assets and open Grok.
