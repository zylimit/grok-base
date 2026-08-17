# /adapters

探测 NFR 可能点名的外部工具是否在 PATH。贴**完整**输出。

Linux / macOS：

```bash
bash .grok/scripts/adapters.sh
```

Windows：

```powershell
pwsh -File .grok/scripts/adapters.ps1
```

默认每行 `PRESENT` 或 `MISSING`，exit 0。

`--strict`（PowerShell: `-Strict`）：任一 `MISSING` → exit 1。NFR 验证方式点名的外部工具不在 PATH → **BLOCKED**，先跑本命令。

这是策展表 + 探测，不是接线引擎。
