# 五性红线（always-on 速查）

开发的系统必须满足五性。详细规程按需读对应 Skill，此处只列红线：

- **韧性 Resilience**：外部依赖必须有超时/重试上限/降级路径；单点故障与恢复路径在设计期声明。缺失 → 设计不通过。
- **网络安全 Security**：不写硬编码密钥；输入在信任边界处校验；默认拒绝（deny-by-default）。发现即 🔴 阻断级。
- **功能安全 Safety**：失效必须落安全侧（fail-safe）；涉及人身/设备/资金的操作要有互锁与幂等。不确定影响时按有伤害处理。
- **隐私 Privacy**：个人数据最小化收集；日志不落敏感字段；数据留存/销毁策略进 Spec。不采集说不清用途的数据。运行态销毁用 `bash .grok/scripts/prune.sh`（默认 dry-run）。
- **可靠性 Reliability**：验收以运行证据为准；关键路径有错误处理且失败可见（禁静默吞错）。无证明命令 = BLOCKED。

路由：需求期 → `nfr-gatekeeper`；设计期 → `threat-modeler`；评审 → code-review 五性 lens；测试 → test-builder 五性用例；发布 → release-builder 五性门禁。
机器门禁：`bash .grok/scripts/fitness.sh`（五性反模式）/ `bash .grok/scripts/adr-check.sh`（ADR 执法引用，幽灵引用失败）。
