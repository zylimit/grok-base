# /nfr-gate

五性门禁。先机器闸，再逐条验证。**没有验证命令输出 = BLOCKED，禁止 PASS。**

1. 当场跑并贴全文：

```bash
bash .grok/scripts/fitness.sh .
bash .grok/scripts/adr-check.sh .
```

Windows 用对应 `.ps1`。

2. 若有 `NFR-Spec.md`：逐条执行其「怎么证明」命令，每条贴输出。

   - 写不出验证命令 → 该条 **BLOCKED**
   - 命令没跑出输出 → 该条 **BLOCKED**
   - 禁止用「看起来符合」记 PASS

3. 汇总：PASS / FAIL / WAIVED / BLOCKED。有 FAIL 或 BLOCKED 则总评不得 PASS。

可选编排：`/workflow nfr-gate path=.`（`.grok/workflows/nfr-gate.rhai`）。
本命令是手工等价物；workflow 只换皮，门禁规则相同。
