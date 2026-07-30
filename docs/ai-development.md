# AI 主导开发规范

> 本项目的核心编码人员是 AI。人的主要职责是确定产品方向、批准规格、审核高风险变更和控制生产权限。

## 1. 目标

AI 主导不等于让模型自由生成代码。项目通过分层约束将模型的不确定性限制在可审查范围内：

```text
OpenSpec       控制“做什么”
架构文档       控制“边界是什么”
AGENTS.md      控制“如何修改仓库”
Pi Skills      控制“遇到特定任务如何工作”
OpenAPI        控制“前后端如何通信”
测试与 CI      控制“结果是否可接受”
人工确认       控制“高风险动作是否允许”
```

提示词和 Skill 是行为引导，不是强制安全边界。编译、测试、CI、最小权限和人工审批才是最终门禁。

## 2. 工具职责

### OpenSpec

用于：

- 新功能和行为变化。
- 跨前端、后端、数据库或 PVE 的改动。
- 权限、审批、配额、安全和回收规则。
- 可验证的验收场景。

不用于：

- HTTP 类型定义；该职责属于 OpenAPI。
- 逐行实现细节。
- 格式化、拼写等不改变行为的小修正。

每个变更应先明确范围、非目标、验收场景、失败路径和迁移影响，再进入实现。

OpenSpec 统一采用中英双语格式：英文规范正文位于前部，是校验、实现和验收的唯一事实来源；中文位于 `## 中文翻译（非规范性）` 下，仅提供完整翻译。中文不得新增或改变要求，规格翻译不得使用 OpenSpec 的 requirement/scenario 操作标题，任务翻译不得使用复选框，以免参与工具解析和开发进度。

### pi CLI

用于读取规范、探索代码、实现、测试和审查。项目优先使用 Pi 原生能力：

- 项目级 `AGENTS.md`。
- 按需加载的 `.pi/skills/`。
- `.pi/prompts/` 中的只读审查和验证模板。
- 必要时使用小型 Extension 拦截危险工具调用。

所有第三方 Pi 包和 Extension 都拥有高权限，安装前必须审查源码并固定版本或提交。

### Ponytail

Ponytail 用于抑制 AI 常见的过度设计：

- 优先删除、复用、标准库和已有依赖。
- 不为假设需求创建抽象。
- 使用最小完整改动修复根因。
- 非简单逻辑保留最小可运行检查。

推荐项目级固定版本安装：

```bash
pi install -l git:github.com/DietrichGebert/ponytail@v4.8.4
```

Ponytail 只控制复杂度，不替代正确性、安全和测试审查。

## 3. 项目内置轻量工作流

本仓库提供两个项目 Skill：

- `systematic-debugging`：禁止在没有证据和根因假设时连续猜修复。
- `verification-before-completion`：禁止在没有新鲜验证结果时声称完成。

提供两个 Prompt Template：

- `/review`：只读审查当前变更，按严重程度报告问题。
- `/verify`：执行适用检查并记录证据。

Issue、Project 和 OpenSpec 已分别承担需求入口、排期和规格职责，因此不安装完整 Superpowers bootstrap、强制 worktree 或子 Agent 编排。

## 4. 标准变更流程

项目跟踪入口固定为 [`CloudPilot-PVE Development`](https://github.com/users/cuihe500/projects/5)。状态流转为：

```text
Backlog → Planned → Spec → In Progress → Testing → In Review → Done
```

Project 使用 P0-P3 Priority 和两周 Iteration。每次状态更新都是门禁；更新失败时停止推进并报告。

### 4.1 登记需求与排期

需求确认后先创建 Issue，正文至少包含目标、范围和可验证验收标准。网页创建使用需求模板，CLI 创建使用：

```bash
gh issue create \
  --repo cuihe500/CloudPilot-PVE \
  --project "CloudPilot-PVE Development" \
  --title "<需求标题>" \
  --body-file <issue-body>
```

Issue 加入 Project 时为 `Backlog`。设置 Priority 和 Iteration 后改为 `Planned`；任一字段缺失时不得进入 OpenSpec。Issue 是唯一 Project 事项，后续 PR 不重复加入。

AI 随后必须：

1. 阅读 `AGENTS.md`、Issue、相关 OpenSpec 和 `docs/architecture.md`。
2. 检查现有实现、调用者、测试和相邻模式。
3. 确认是否涉及信任边界或数据迁移。
4. 发现仓库事实与需求冲突时先说明，不自行选择更方便的解释。

### 4.2 形成和批准规格

开始编写 OpenSpec 前将 Project 状态改为 `Spec`，且提案必须引用 Issue。以下任一条件成立时创建或更新 OpenSpec：

- 新增用户可见行为。
- 修改 API、数据库或状态转换。
- 涉及权限、配额、审批、审计或 PVE 写操作。
- 需要修改多个组件。
- 验收方式不明确。

规格至少覆盖目标、范围、非目标、正常/失败流程、权限与审批要求及可自动化验收场景。OpenSpec 未获批准不得实现；批准并开始开发时将状态改为 `In Progress`。

### 4.3 建立分支并实现

`main` 只接收通过 PR 合并的变更。文档、小修复和自动生成变更也不能直接提交到 `main`。

```bash
git status --short
git switch main
git pull --ff-only origin main
git switch -c <type>/<short-topic>
```

- 工作树必须干净，分支必须来自最新 `origin/main`。
- 一个分支对应一个 Issue/OpenSpec 或一个内聚小任务。
- 分支类型使用 `feat`、`fix`、`docs`、`chore`、`refactor`、`test`。
- AI 使用独立机器账号；项目 Owner `@cuihe500` 不作为 PR 作者。
- 禁止直接推送 `main`、强制推送或改写已公开提交历史。
- 实现优先复用现有代码、标准库、平台能力和已批准依赖；禁止顺手重构和投机抽象。

### 4.4 测试与只读审查

实现完成后先将 Project 状态改为 `Testing`，再执行：

1. 针对性测试。
2. `/verify` 和适用的 `make check`。
3. `/review`，并处理有效发现。
4. 检查 diff、暂存区、工作树、秘密和无关文件。

审查必须确认满足 OpenSpec，并检查越权、审批/配额绕过、秘密泄露、幂等/事务/重试/回收安全、无必要依赖，以及 OpenAPI、迁移、生成文件和文档同步。修正后重新运行受影响检查。没有可运行命令时必须明确记录未验证项和原因。

### 4.5 提交 PR 与评审

提交信息使用 Conventional Commits。有对应需求的 PR 必须关联 Issue 和 OpenSpec；不改变行为的小修正填写 `N/A` 和原因：

```markdown
Closes #123

OpenSpec: `openspec/changes/<change-id>/`
```

推送并创建 PR：

```bash
git push -u origin HEAD
gh pr create --base main --head "$(git branch --show-current)"
```

PR 正文必须包含背景、实际修改、验证证据、安全与风险、契约/迁移、界面证据和未完成项。有对应 Issue 时，创建成功后立即把其 Project 状态改为 `In Review`。

- Reviewers 必须包含 `@cuihe500`，并由其完成 Owner 审查。
- `.github/CODEOWNERS` 为所有路径指定 `@cuihe500`。
- 评审修正在同一分支追加提交，重新验证并更新 PR 正文。
- `@cuihe500` 批准、CI 通过且评审对话全部解决前不得合并。

### 4.6 合并与结束需求

PR 合并后，`Closes #<issue>` 自动关闭 Issue，Project 内置工作流将状态更新为 `Done`。必须实际确认 Issue 已关闭且状态为 `Done` 后才能报告需求结束。若自动更新失败，手工修正并记录原因。后续工作从更新后的 `main` 新建分支。

## 5. 质量门禁

项目初始化完成后，`make check` 至少应覆盖：

### Go

```text
gofmt 检查
go vet ./...
go test ./...
```

CI 额外执行：

```text
go test -race ./...
govulncheck ./...
```

只有标准工具不能覆盖且出现明确价值时才引入额外 lint 聚合器。

### TypeScript / Vue

```text
vue-tsc --noEmit
eslint
vitest run
vite build
```

### 契约与数据库

```text
生成 OpenAPI 对应的 Go/TypeScript 类型
检查生成后 git diff
在临时 PostgreSQL 上执行全部迁移
```

### 端到端

至少保留一条黄金路径：

```text
申请 → 计划预览 → 审批 → 模拟 PVE 执行 → 结果/审计
```

端到端测试不得连接生产 PVE。

## 6. 风险分级

| 级别 | 示例 | 最低要求 |
|---|---|---|
| 低 | 文案、样式、内部重命名 | 相关检查和 diff 审查 |
| 中 | 普通 API、查询、表单、非关键状态 | 单元/集成测试、`make check`、`/review` |
| 高 | 认证、RBAC、配额、审批、迁移、PVE 写操作、回收 | OpenSpec、失败场景测试、集成测试、完整检查、人工审查 |
| 生产操作 | 部署、真实 PVE、破坏性迁移、秘密轮换 | 人工明确确认并使用独立运维流程 |

AI 不得自行降低风险级别。

## 7. 安全 Extension 计划

在进入可运行代码阶段前，增加一个最小 `.pi/extensions/safety-gate.ts`，只负责硬拦截：

- 修改 `.env`、凭据目录和生成代码。
- `rm -rf`、`sudo`、`git reset --hard`、强制推送等危险命令。
- 从开发工具直接连接生产 PVE。
- 未经确认执行破坏性迁移或部署。

Extension 不承担代码审查，也不在每轮自动运行全部测试。检查应通过 `make check` 和 CI 完成。

## 8. AI 上下文管理

为减少长会话漂移：

- 需求目标和进度写入 Issue/Project，批准后的行为要求写入 OpenSpec，不依赖聊天历史。
- 架构事实写入 `docs/architecture.md`。
- API 事实写入 OpenAPI。
- 当前工作状态使用 Git diff、测试输出和任务清单表达。
- 大任务按可独立验证的行为切分，而不是按技术层机械切分。
- 压缩或恢复会话后重新读取相关规范和当前 diff。

不要把临时讨论、模型思考过程或重复的计划长期写入仓库。

## 9. 人工职责

即使 AI 是核心编码人员，人仍必须负责：

- 批准需求和 OpenSpec。
- 审查认证、授权、审批、配额、迁移和回收规则。
- 管理模型、数据库和 PVE 凭据。
- 批准生产部署及真实基础设施变更。
- 对重大架构偏离作最终决定。

人工审批不能被“AI 已审查”替代。

## 10. 文档维护

变更对应关系：

| 变更 | 必须同步 |
|---|---|
| 产品行为 | OpenSpec、相关测试 |
| HTTP API | `api/openapi.yaml`、生成类型 |
| 架构边界或技术选型 | `docs/architecture.md` |
| AI 开发流程和门禁 | GitHub Project、Issue/PR 模板、`AGENTS.md`、本文或 `.pi/` 资源 |
| 数据模型 | OpenSpec、迁移、架构文档中的相关部分 |
| 部署入口 | 部署配置、架构文档 |

文档只记录当前决策和已批准方向，不记录没有触发条件的未来设计。
