# /recap

同步三文件。缺哪个就说哪个，不编造。

1. 读 `progress.md`
   - 有：摘 Pinned / Decisions / In Progress / 最近 Done
   - 无：写明「无 progress.md，降级：只根据会话与其它文件」
2. 读 `Product-Spec.md`
   - 有：摘产品概述、当前范围、未决问题
   - 无：写明「无 Product-Spec，降级：不按 Spec 验收」
3. 读 `Product-Spec-CHANGELOG.md`
   - 有：摘最近版本与变更
   - 无：写明「无 CHANGELOG，降级：不追踪需求 diff」

输出必须含：

- 三文件各自：存在 / 缺失（缺失 = 降级，点名缺什么）
- 当前阶段与下一步（有 progress 用其；否则据 Spec 推断并标明「推断」）
- 若 `.grok/.needs-review` 存在且不是单独一行 `clean`：列出待审路径

禁止：把缺失文件当成空 Spec；禁止「应该还好」。
