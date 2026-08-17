# /gate-audit

读 `.grok/hooks/gate-log.tsv`，按 hook 聚合 deny 次数。贴**完整**输出。

Linux / macOS：

```bash
bash .grok/scripts/gate-audit.sh .
```

Windows：

```powershell
pwsh -File .grok/scripts/gate-audit.ps1 -Target .
```

无文件：打印 `no log yet`，exit 0。
只统计，不自动删闸、不改 hooks。
