## Context

Issue #14 changes the credential-lifecycle policy for the existing `CloudPilot PVE PR Bot`. The checked-in CLI already signs a short-lived App JWT, exchanges it for a short-lived installation token, and sets that token as `GH_TOKEN` only for the `gh` child process that performs each bot API call. It does not call `gh auth login` for the App. The current specification and documentation nevertheless require removal of the Owner's ambient `gh` login after App acceptance.

The Owner has explicitly approved coexistence of the ambient Owner login and the PR Bot credentials. The security boundary must therefore be expressed by operation identity, not by deleting a separate login: bot-created or bot-maintained PR operations use the App installation token; the Owner remains the independent reviewer.

## Goals / Non-Goals

**Goals:**

- Give contributors one clear, copyable workflow for submitting a review-ready PR through the bot.
- Permit an Owner `gh` login to remain available without allowing it to become the identity that creates or maintains AI-authored PRs.
- Preserve short-lived, process-scoped App tokens and all existing App permission and review boundaries.
- Update the current normative `pr-bot` specification and user-facing documentation consistently.

**Non-Goals:**

- Changing the App manifest, permissions, private-key location, token lifetime, branch protection, CODEOWNERS, or bot command surface.
- Adding token persistence, a second `gh` profile, a machine user, a hosted service, or a new dependency.
- Rewriting archived OpenSpec artifacts, which remain historical records of the original bootstrap decision.

## Decisions

### Retain the existing CLI token path

`pr-bot.sh` already supplies a newly obtained installation token through `GH_TOKEN` for every bot API call. The documentation and specification will rely on that explicit per-process override rather than introduce a second authentication mechanism or modify `gh`'s stored login.

Alternative considered: log out the Owner after bootstrap. Rejected because the Owner has approved coexistence and logout unnecessarily disrupts legitimate Owner tooling without improving the App token's isolation.

### Bind AI PR mutations to the bot command

The guide will require `./scripts/pr-bot.sh verify` before use, `create` to create or resume a bot-owned PR, and `status` to read the resulting bot-owned PR. It will explicitly prohibit using ambient Owner authentication with `gh pr create` or equivalent direct PR mutation commands for AI-authored changes.

Alternative considered: add a new wrapper or change the CLI. Rejected because the existing CLI already verifies installation identity, remote branch, base branch, body completeness, bot ownership, reviewer confirmation, and Ready transition.

### Keep the Owner review boundary unchanged

The bot remains the PR author and requests `@cuihe500`; the Owner's retained `gh` login does not authorize the bot or replace the independent GitHub review. The guide will state that review and merge remain human Owner actions subject to the existing branch protection.

### Update only current sources of truth

The implementation will modify the current main `pr-bot` specification through this delta, the detailed `docs/pr-bot.md` guide, and the shared PR command in `docs/ai-development.md`. The archived `setup-pr-bot` proposal, design, tasks, and delta spec will not be rewritten because they describe the decision at the time of the original change.

## Risks / Trade-offs

- [Ambient Owner authentication can be used accidentally for a direct PR mutation] → The guide makes `scripts/pr-bot.sh` mandatory for AI PR creation and maintenance; the bot also verifies its App identity and requested Owner reviewer.
- [A retained login may be mistaken for the bot credential] → Document that the bot obtains a fresh installation token on each invocation and injects it only as the child process `GH_TOKEN`; no App credential is stored in `gh auth`.
- [Missing or invalid bot configuration blocks PR submission] → Run `./scripts/pr-bot.sh verify` before preparing the PR and let the existing fail-closed checks stop the workflow.

## Migration Plan

1. Publish the delta requirement that replaces mandatory Owner-login removal with bounded credential coexistence.
2. Update the PR Bot guide and the shared AI development PR command with preflight, body preparation, `verify`, `create`, status, and failure-handling steps.
3. Do not run `gh auth logout` as part of App acceptance; retain existing Owner sessions if they are needed for Owner operations.
4. Validate OpenSpec artifacts, Markdown links, shell syntax, the existing bot tests, and the repository checks appropriate to documentation-only changes.

Rollback restores the prior documentation and current `Owner credential isolation` requirement in a follow-up change. It does not require App reinstallation, permission changes, token revocation, or branch-protection changes.

## Open Questions

None. The Owner explicitly confirmed the coexistence policy and the requirement that PR Bot operations continue to use temporary installation tokens.

## 中文翻译（非规范性）

### 背景

Issue #14 调整既有 `CloudPilot PVE PR Bot` 的凭据生命周期策略。当前 CLI 已经会签发短期 App JWT、换取短期 Installation Token，并仅在每次机器人 API 调用对应的 `gh` 子进程中将该 Token 设置为 `GH_TOKEN`；它不会为 App 执行 `gh auth login`。但当前规范和文档仍要求 App 验收后移除 Owner 的环境 `gh` 登录。

Owner 已明确同意保留 Owner 登录并与机器人凭据共存。因此安全边界应由操作所用身份界定，而不是删除另一份登录：机器人创建或维护 PR 时使用 App Installation Token，Owner 继续作为独立审查人。

### 目标与非目标

本设计提供可复制的机器人 PR 提交流程，允许保留 Owner `gh` 登录但不让其成为 AI PR 的创建或维护身份，并保持短期、进程范围的 App Token 及现有权限与审查边界。它不改变 App Manifest、权限、私钥位置、Token 时效、分支保护、CODEOWNERS 或 CLI 命令面；也不引入新的认证机制、依赖或服务，更不会改写历史归档的 OpenSpec 记录。

### 决策

继续使用既有 CLI 的逐次 Installation Token 路径，而非新增认证机制或修改 `gh` 的已存登录。文档要求先执行 `verify`，再使用 `create` 创建或恢复机器人拥有的 PR，并使用 `status` 查询状态；AI 不得以环境中的 Owner 身份直接调用 `gh pr create` 或等效 PR 修改命令。机器人仍然是 PR 作者并请求 `@cuihe500`，保留的 Owner 登录不会代替人工审查。现行 `pr-bot` 规范、详细机器人指南和共享 AI PR 命令将同步更新；归档记录保持不变。

### 风险与取舍

环境中的 Owner 登录可能被误用于直接 PR 修改，因此文档会把 `scripts/pr-bot.sh` 作为 AI PR 创建和维护的唯一入口，机器人也会核验自身 App 身份和 Owner 审查人。保留的登录可能被误认为机器人凭据，因此文档会说明机器人每次调用都重新获取 Installation Token，并仅以子进程 `GH_TOKEN` 注入；App 凭据不保存在 `gh auth` 中。机器人配置缺失或无效时，先运行 `verify`，并让现有的失败关闭检查中止流程。

### 迁移与回滚

实施时发布新的增量规格、更新 PR Bot 指南和共享 AI PR 命令，并取消在 App 验收阶段执行 `gh auth logout` 的做法。验证将覆盖 OpenSpec、Markdown 链接、Shell 语法、既有机器人测试和适用于纯文档变更的仓库检查。若需回退，可在后续变更中恢复旧文档和旧规则；不需要重新安装 App、调整权限、撤销 Token 或修改分支保护。

### 未决事项

没有未决事项；Owner 已明确确认可共存策略，并要求机器人操作继续使用临时 Installation Token。
