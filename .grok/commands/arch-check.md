# /arch-check

跑边界棘轮 + ADR 执法。两份输出都要全文粘贴。

1. 架构边界：

```bash
bash .grok/scripts/arch-check.sh .
```

Windows：`pwsh -File .grok/scripts/arch-check.ps1 .`

2. ADR 引用：

```bash
bash .grok/scripts/adr-check.sh .
```

Windows：`pwsh -File .grok/scripts/adr-check.ps1 .`

3. 读两份完整输出 + exit code。

   - 无 `docs/adr/` 时 adr-check 打印 `nothing to check` 且 exit 0：合法空集，不是漏跑
   - 任一命令无输出、且不是 `nothing to check` → **BLOCKED**
   - 新违规 / 幽灵 `Enforced-by` → FAIL
   - 两份都绿 → 才可说通过

禁止改 `boundaries.txt` 消红，除非用户授权走 arch-guardian。
