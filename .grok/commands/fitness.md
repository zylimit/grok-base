# /fitness

跑五性反模式扫描。贴**完整**输出。没有输出不得说 PASS。

Linux / macOS：

```bash
bash .grok/scripts/fitness.sh .
```

Windows：

```powershell
pwsh -File .grok/scripts/fitness.ps1 .
```

然后：

1. 把该命令的 stdout + stderr **全文**贴进回复（禁止只贴摘要）
2. 读 exit code
3. 结论：
   - exit 0 且输出支持 → PASS
   - 有 finding 或非零 → FAIL，列 `rule` 与 `file:line`
   - 命令没跑出任何输出 → **BLOCKED**（不当 PASS）

脚本约定：每行 `rule<TAB>file:line<TAB>snippet`，末尾计数。exit 1 = 有 finding。
