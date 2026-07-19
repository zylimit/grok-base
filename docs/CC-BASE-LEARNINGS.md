# cc-base 深入学习笔记（给 grok-base 抄作业）

参考仓：`D:\Code\cc-base`（纯 Claude Code 脚手架）。  
原则：**工作流与工程纪律可抄；运行时载体必须 Grok 原生**（`AGENTS.md` + `.grok/` + `spawn_subagent` + hooks JSON）。

---

## 1. 交付形态：安装器是一等公民

| 能力 | cc-base | grok-base 应对 |
|---|---|---|
| 注入安装 | `setup.sh` / `setup.ps1` | **已抄**：根目录 `setup.ps1` / `setup.sh` |
| 升级分层 | `FRAMEWORK-MANIFEST.txt` + `.framework-new` | **已抄**：`gen-manifest` + setup 对照 SHA |
| 装后自检 | `doctor.sh` | **已抄**：`.grok/scripts/doctor.ps1` / `doctor.sh`（含 spawn smoke） |
| 跳过运行态 | `.needs-review` / `.fast-mode` / 私人 feedback | setup 跳过 + 重置 FEEDBACK-INDEX |
| 平台 hooks | settings 里改写 sh→pwsh 绝对路径 | setup 写 `.cmd` / Unix 写 `bash …sh` |
| 幂等回归 | `tests/test-setup.sh` | **待抄**：装到临时目录断言 |

**血泪点（Windows）**：hook 解释器必须 **pwsh 7 绝对路径**（`ProgramW6432`），禁裸 `powershell.exe` 5.1（超时/PATH 污染）。见 cc-base feedback `hook-interpreter-use-pwsh7-not-powershell51.md`。

---

## 2. 主控分层：瘦主控 + rules 下沉

cc-base：

- `CLAUDE.md`：角色、纪律、路由、派发（仍偏厚，但细则已开始下沉）
- `rules/file-structure.md` / `workflow-orchestration.md` / `dev-workflow-details.md`：按需再读

**可抄**：

- 主控只留路由 + 铁律指针  
- 超长流程放 Skill / `rules/`，避免单文件膨胀  

**Grok 侧**：可用 `.grok/rules/*.md`（官方 rules 目录）或继续靠 Skills。主控保持精简。

---

## 3. 编排模型

| 点 | cc-base | grok-base |
|---|---|---|
| 主 Agent | 唯一编排者，不写业务码 | 同（AGENTS 铁律） |
| 工人 | 7 Sub-Agent fresh | 7 agents/roles/personas |
| 扁平 | 禁止 Sub 再 Sub | Grok 内建 depth=1 |
| 并行 | Workflow fan-out 用于**只读**审查/测试/研究；**编码默认串行** | 同原则写进 AGENTS |
| 验收 | 客观证据；子 Agent 自述不算 | 同 + 五步闸 |

**不要抄**：Claude Dynamic Workflows JS API、Task 工具语法——Grok 用 `spawn_subagent`。

---

## 4. Hook 矩阵（cc-base 已注册 ~13 类）

| Hook | 作用 | Grok 现状 / 建议 |
|---|---|---|
| detect-feedback-signal | 用户修正用语 | 有 detect-feedback |
| check-evolution | 待处理 feedback | 可并入 session-start |
| session-rules-banner | Session 铁律横幅 | **应抄** |
| recap-on-dirty | 脏树提醒 /recap | 已在 session-start |
| dangerous-pkill-guard | 禁 pkill -f | 有 block-pkill |
| pre-commit-check | commit 前编译 | 有 |
| kill-dev-ports | 启 dev 前清端口 | **可抄** |
| tdd-gate | TDD 卡点 | 可选 / Fast Mode 旁路 |
| no-direct-code-guard | 主 Agent 禁写业务源码 | **应抄** |
| mark-review-needed | 改业务文件登记待审 | 有 |
| auto-push | commit 后 push | **默认关**（cc 有，我们保持关） |
| stop-gate | 待审阻止 Stop | Grok Stop 不能硬拦 → reminder |
| three-file-sync-gate | Spec/progress 同步 | reminder 或 PreToolUse 软提示 |
| subagent-acceptance-reminder | SubagentStop 提醒验收 | Grok 有 SubagentStop 事件 **可抄** |

**平台铁律**：每个 hook **.sh + .ps1/.cmd 双写**；行为等价；Windows 用 cmd 入口 + 真 pwsh。

---

## 5. Feedback 进化系统

cc-base 特点：

- 主题文件 + `FEEDBACK-INDEX.md`  
- frontmatter：`occurrences` / `scores` / `graduated`  
- evolution-runner 只提议，用户确认才改规则  
- **血泪条目本身就是产品资产**（pwsh7、远端实查、完成五步闸、三文件同步…）

**可抄**：

- 不把私人 feedback 打进发布包（setup 已重置 INDEX）  
- 把高频反馈**毕业**进 AGENTS / Skill，而不是无限堆反馈文件  

**优先毕业进 grok AGENTS 的条目**：

1. 完成声明五步闸  
2. 主 Agent 不直接写业务码  
3. 审批三档 LOW/MEDIUM/HIGH  
4. 远端写操作先实查  
5. Skill 1% 即调  

---

## 6. 测试与发布资产

cc-base 有完整：

- `tests/test-setup.sh` 安装幂等  
- `test-routing.sh` 静态锚点守护 AGENTS 关键字  
- `test-fast-mode.sh` / gate-audit  
- `make-release.sh` 打 zip + 排除私人内容  

**待抄优先级**：

| P0 | setup + doctor + manifest（已做） |
| P1 | test-setup（临时目录装一遍 + spawn smoke） |
| P2 | test-routing（AGENTS 必含锚点） |
| P3 | make-release |

---

## 7. 审批与授权（行为一致性）

cc-base 审批三档：

- **LOW** 不问：写文档/progress、加测试、只读探索  
- **MEDIUM** 一句话预告：长 Sub-Agent、批量重构  
- **HIGH** 必停：删家底 hook/skill、push/发版、生产写、密钥  

这比「遇到事就问要不要继续」更稳，不同 session 松紧一致。

---

## 8. 明确不要抄的

- Claude `settings.json` / `$CLAUDE_PROJECT_DIR` 原样搬  
- Dynamic Workflows JS 运行时  
- auto-push 默认开  
- 把 Stop 硬拦截当 Grok 能力（Grok 做不到）  
- 与 codex 同仓双主控硬叠  

---

## 9. 抄作业进度（本仓）

| 项 | 状态 |
|---|---|
| setup.ps1 / setup.sh | 已有 |
| doctor + spawn smoke | 已有 |
| gen-manifest + FRAMEWORK-MANIFEST | 已有 |
| Windows .cmd + 延迟 ERRORLEVEL + ProgramW6432 pwsh | 已有 |
| session-rules-banner | 进行中 |
| no-direct-code-guard | 进行中 |
| 五步闸 / 审批三档写进 AGENTS | 进行中 |
| test-setup / release | 待做 |

---

## 10. 一句话

> cc-base 的精华不是「多一个 setup 文件」，而是 **注入适配 + 升级分层 + hook 双写 + feedback 血泪铁律 + 装后自检** 组成的工程闭环。  
> grok-base 抄这个闭环，运行时仍只认 Grok 官方表面。
