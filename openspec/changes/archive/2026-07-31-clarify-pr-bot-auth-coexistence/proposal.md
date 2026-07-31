## Why

Issue #14 confirms that the Owner's `gh` login may coexist with the CloudPilot PVE PR Bot. The current `pr-bot` requirement instead mandates removing that login after App acceptance, even though the bot already overrides ambient GitHub credentials with a short-lived App installation token for every GitHub API call. This creates avoidable operational disruption and leaves the required bot submission procedure insufficiently explicit.

## What Changes

- Replace the current requirement to remove the Owner `gh` login with a requirement that permits coexistence while keeping PR Bot API calls authenticated exclusively with short-lived App installation tokens.
- Document the complete PR submission workflow: prepare an already-pushed branch and complete PR body, verify the App installation, create or resume the bot-owned PR, and query its status.
- State that AI-authored PR creation and maintenance must invoke `scripts/pr-bot.sh`; an ambient Owner login must not be used with `gh pr create` or equivalent direct PR mutation commands.
- Retain the existing least-privilege App permissions, external secret storage, short-lived token handling, Draft-first reviewer confirmation, Owner review boundary, and prohibited-operation limits.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `pr-bot`: Replace post-acceptance Owner credential removal with bounded credential coexistence and make the bot submission procedure explicit.

## Impact

- Documentation: `docs/pr-bot.md` gains an operational PR submission guide and revised credential guidance; `docs/ai-development.md` routes its shared AI PR workflow through the bot.
- Specification: the current `openspec/specs/pr-bot/spec.md` requirement changes through a delta spec.
- No GitHub App permissions, branch protection, API contracts, application code, dependencies, database schema, or PVE integration change.

## 中文翻译（非规范性）

### 原因

Issue #14 已确认 Owner 的 `gh` 登录可以与 CloudPilot PVE PR Bot 共存。当前 `pr-bot` 规范却要求在 App 验收后移除该登录；但机器人每次调用 GitHub API 时已经使用短期 App Installation Token 显式覆盖环境中的 GitHub 凭据。该要求会造成不必要的运维中断，同时现有文档对机器人提交 PR 的步骤说明也不够明确。

### 变更内容

本变更会将“验收后移除 Owner `gh` 登录”的现行规则替换为“允许凭据共存，但 PR Bot 的 API 调用只能使用短期 App Installation Token”的规则。文档将完整说明提交 PR 的流程：准备已经推送的分支和完整 PR 正文、验证 App 安装、创建或恢复机器人拥有的 PR，以及查询该 PR 状态。AI 创建或维护 PR 时必须调用 `scripts/pr-bot.sh`；不得借助环境中存在的 Owner 登录执行 `gh pr create` 或等效的直接 PR 修改命令。GitHub App 最小权限、仓库外秘密存储、短期 Token、Draft-first 审查人确认、Owner 审查边界和禁止操作范围均保持不变。

### 能力范围

本变更不引入新能力，只修改现有 `pr-bot` 能力中的凭据生命周期规则，并明确机器人提交流程。

### 影响

将更新 `docs/pr-bot.md` 中的操作指南和 `docs/ai-development.md` 中的共享 AI PR 流程，并更新现行 `pr-bot` 规范的增量规格。GitHub App 权限、分支保护、API 契约、应用代码、依赖、数据库结构和 PVE 集成均不受影响。
