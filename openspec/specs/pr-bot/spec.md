# pr-bot Specification

## Purpose

Define the dedicated GitHub App identity, least-privilege credentials, fail-closed PR lifecycle, Owner review boundary, and repository protection used for AI-authored changes.

## Requirements

### Requirement: Repository-scoped App identity
The PR bot SHALL be a private GitHub App named `CloudPilot PVE PR Bot`, owned by `@cuihe500`, and installed only on `cuihe500/CloudPilot-PVE`.

#### Scenario: Owner installs the App
- **WHEN** the Owner completes GitHub App registration and installation
- **THEN** the installation includes only `cuihe500/CloudPilot-PVE`
- **THEN** webhooks, OAuth authorization, and Device Flow are disabled

### Requirement: Least-privilege permissions
The App SHALL have only Metadata read, Contents read, and Pull requests write repository permissions.

#### Scenario: Permission configuration is verified
- **WHEN** setup reads the installed App permissions
- **THEN** the three approved permissions match their required access levels
- **THEN** no code-write, administration, Actions, secrets, deployments, Issues, or Releases permission is granted

### Requirement: External credential storage
The bot SHALL keep its private key and installation configuration outside the repository and SHALL use only short-lived installation tokens for API calls.

#### Scenario: Credential files are valid
- **WHEN** the CLI loads bot credentials
- **THEN** it reads them from `~/.config/cloudpilot-pve-pr-bot/`
- **THEN** `private-key.pem` has mode `0600`
- **THEN** repository owner, name, App ID, installation ID, and App slug match the expected values

#### Scenario: Installation token is requested
- **WHEN** the CLI needs to call GitHub
- **THEN** it signs a short-lived App JWT and exchanges it for a short-lived installation token
- **THEN** the token is provided through the command process environment only
- **THEN** neither token nor private key is printed or stored by `gh auth login`

### Requirement: PR creation preflight
The bot SHALL create PRs only from existing remote development branches to `main` in the configured repository.

#### Scenario: Valid source branch
- **WHEN** the source branch exists on the configured remote, is not `main`, and has changes relative to `main`
- **THEN** the bot may continue to PR body validation

#### Scenario: Invalid source or target
- **WHEN** the source is missing, equals `main`, has no changes, or the requested target is not `main`
- **THEN** the command exits non-zero before creating a PR

### Requirement: Complete PR description
The bot SHALL reject a PR body that omits required review information.

#### Scenario: Body is complete
- **WHEN** the body contains Issue, OpenSpec, background, changes, verification, risks, contract or migration impact, UI evidence, and unfinished work sections
- **THEN** the bot may create or update the Draft PR

#### Scenario: Body is incomplete
- **WHEN** any required section is absent or empty without an explicit not-applicable explanation
- **THEN** the command exits non-zero and does not mark a PR ready

### Requirement: Draft-first Owner review
The bot SHALL keep a new PR in Draft until `@cuihe500` is confirmed as a requested reviewer.

#### Scenario: Reviewer request succeeds
- **WHEN** a Draft PR has a complete body and GitHub confirms `@cuihe500` in requested reviewers
- **THEN** the bot marks the PR ready for review

#### Scenario: Reviewer request fails
- **WHEN** GitHub rejects the reviewer request or the subsequent read does not contain `@cuihe500`
- **THEN** the PR remains Draft
- **THEN** the command exits non-zero without closing the PR or deleting the branch

### Requirement: Idempotent PR orchestration
The bot SHALL avoid duplicate PRs and SHALL modify only an open PR created by its own App identity for the same head and base.

#### Scenario: Matching bot Draft exists
- **WHEN** the create command finds a matching open Draft created by the configured App
- **THEN** it resumes safe body validation and reviewer confirmation on that PR
- **THEN** it does not create another PR

#### Scenario: Conflicting PR exists
- **WHEN** an open PR for the same head and base was created by another identity
- **THEN** the command exits non-zero without modifying that PR

### Requirement: Prohibited operations
The bot SHALL NOT push or modify code, merge or close PRs, submit reviews, delete branches, modify repository settings, manage Actions or secrets, deploy software, or access PVE.

#### Scenario: CLI command surface is inspected
- **WHEN** the checked-in bot CLI is reviewed or tested
- **THEN** it exposes no command or API route for a prohibited operation

### Requirement: Protected main branch
The repository SHALL require Owner approval before a PR can merge to `main`.

#### Scenario: Branch protection is configured
- **WHEN** protection for `main` is read
- **THEN** at least one approving review and CODEOWNER review are required
- **THEN** stale approvals are dismissed and review conversations must be resolved
- **THEN** administrators are included, linear history is required, and force pushes and deletion are disabled

#### Scenario: Last-push approval remains deferred
- **WHEN** the Owner-associated Git transport may still push development branches
- **THEN** approval of the most recent push is not required
- **THEN** the limitation is documented until a separate code-push identity exists

### Requirement: Owner credential coexistence
The AI environment MAY retain an Owner `gh` login after the App has passed its acceptance checks. For every GitHub API call that creates, updates, requests review on, or reads a bot-owned PR, the PR Bot SHALL obtain a short-lived App installation token and provide it only through the corresponding child process `GH_TOKEN`. AI-authored PR creation and maintenance SHALL invoke `scripts/pr-bot.sh` and SHALL NOT use the ambient Owner login with `gh pr create` or an equivalent direct PR mutation command.

#### Scenario: Owner login remains available after App acceptance
- **WHEN** the App has passed its acceptance checks and an Owner `gh` login remains configured in the AI environment
- **THEN** no logout operation is required for the bot to operate
- **THEN** each bot API invocation authenticates with its own short-lived App installation token rather than the ambient Owner login

#### Scenario: AI submits a PR through the bot
- **WHEN** an AI creates or maintains a PR for an already-pushed development branch
- **THEN** it invokes `scripts/pr-bot.sh` rather than a direct Owner-authenticated PR mutation command
- **THEN** the resulting PR is authored or updated only when it is owned by the configured App identity and `@cuihe500` is confirmed as a requested reviewer

#### Scenario: Bot token remains process-scoped
- **WHEN** a bot command completes its GitHub API operation
- **THEN** the installation token is not printed, written to the repository, or stored by `gh auth login`

---

## 中文翻译（非规范性）

> 本节仅为英文规范正文的翻译，不参与 OpenSpec 解析、校验、实现或验收；如有歧义，以英文为准。

**目的**

定义用于 AI 创建变更的专用 GitHub App 身份、最小权限凭据、失败关闭的 PR 生命周期、Owner 审查边界和仓库保护措施。

**需求一：仓库范围内的 App 身份**

PR 机器人是名为 `CloudPilot PVE PR Bot` 的私有 GitHub App，归 `@cuihe500` 所有，并且仅安装到 `cuihe500/CloudPilot-PVE`。

**场景：Owner 安装 App**

- 条件：Owner 完成 GitHub App 注册和安装。
- 结果：安装范围仅包含 `cuihe500/CloudPilot-PVE`。
- 结果：Webhook、OAuth 授权和 Device Flow 均被禁用。

**需求二：最小权限**

App 仅具有 Metadata 读、Contents 读和 Pull requests 写的仓库权限。

**场景：核验权限配置**

- 条件：安装流程读取已安装 App 的权限。
- 结果：三项允许的权限与规定的访问级别一致。
- 结果：不会授予代码写入、管理、Actions、Secrets、部署、Issues 或 Releases 权限。

**需求三：仓库外的凭据存储**

机器人将私钥和安装配置保存在仓库外，并仅使用短期 Installation Token 调用 API。

**场景：凭据文件有效**

- 条件：CLI 加载机器人凭据。
- 结果：它从 `~/.config/cloudpilot-pve-pr-bot/` 读取凭据。
- 结果：`private-key.pem` 的权限为 `0600`。
- 结果：仓库 Owner、仓库名称、App ID、Installation ID 和 App slug 与预期值一致。

**场景：请求 Installation Token**

- 条件：CLI 需要调用 GitHub。
- 结果：它签发短期 App JWT，并将其交换为短期 Installation Token。
- 结果：Token 仅通过命令进程环境传递。
- 结果：Token 和私钥不会被输出，也不会由 `gh auth login` 保存。

**需求四：创建 PR 前的检查**

机器人只从已存在的远端开发分支向已配置仓库中的 `main` 创建 PR。

**场景：有效源分支**

- 条件：源分支存在于远端、不等于 `main`，并且相对 `main` 有变更。
- 结果：机器人可以继续校验 PR 正文。

**场景：无效源或目标**

- 条件：源分支缺失、等于 `main`、没有变更，或者请求的目标不是 `main`。
- 结果：命令在创建 PR 前以非零状态退出。

**需求五：完整 PR 描述**

机器人拒绝缺少必需审查信息的 PR 正文。

**场景：正文完整**

- 条件：正文包含 Issue、OpenSpec、背景、修改、验证、风险、契约或迁移影响、界面证据和未完成项章节。
- 结果：机器人可以创建或更新 Draft PR。

**场景：正文不完整**

- 条件：任何必需章节缺失，或在没有明确不适用说明时为空。
- 结果：命令以非零状态退出，且不会将 PR 设为 Ready。

**需求六：先 Draft 后 Owner 审查**

在确认 `@cuihe500` 已被请求为 Reviewer 前，机器人会保持新 PR 为 Draft。

**场景：Reviewer 请求成功**

- 条件：Draft PR 具有完整正文，且 GitHub 确认 `@cuihe500` 位于被请求审查人中。
- 结果：机器人将 PR 设为 Ready for review。

**场景：Reviewer 请求失败**

- 条件：GitHub 拒绝 Reviewer 请求，或随后读取结果中不含 `@cuihe500`。
- 结果：PR 保持 Draft。
- 结果：命令以非零状态退出，不关闭 PR，也不删除分支。

**需求七：幂等 PR 编排**

机器人避免重复 PR，并且只修改同一源分支和目标分支下由自身 App 身份创建的开放 PR。

**场景：存在匹配的机器人 Draft**

- 条件：创建命令找到由已配置 App 创建的匹配开放 Draft。
- 结果：它在该 PR 上安全恢复正文校验和 Reviewer 确认。
- 结果：不会创建另一个 PR。

**场景：存在冲突 PR**

- 条件：同一源分支和目标分支已有其他身份创建的开放 PR。
- 结果：命令以非零状态退出，且不修改该 PR。

**需求八：禁止操作**

机器人不得推送或修改代码、合并或关闭 PR、提交 Review、删除分支、修改仓库设置、管理 Actions 或 Secrets、部署软件或访问 PVE。

**场景：检查 CLI 命令面**

- 条件：审查或测试已提交的机器人 CLI。
- 结果：它不暴露任何用于禁止操作的命令或 API 路径。

**需求九：受保护的 main 分支**

仓库要求 Owner 批准后才能将 PR 合并到 `main`。

**场景：配置分支保护**

- 条件：读取 `main` 的保护配置。
- 结果：至少要求一个批准 Review 和 CODEOWNER Review。
- 结果：旧批准会被撤销，并且必须解决所有 Review 对话。
- 结果：保护包括管理员、要求线性历史，并禁用强制推送和分支删除。

**场景：最近推送批准暂缓**

- 条件：Owner 关联的 Git 传输仍可能推送开发分支。
- 结果：暂不要求最近一次推送的批准。
- 结果：该限制会被记录，直到存在独立的代码推送身份。

**需求十：Owner 凭据共存**

App 通过验收后，AI 环境可以继续保留 Owner 的 `gh` 登录。机器人每次创建、更新、请求审查或读取机器人拥有的 PR 时，都重新获取短期 App Installation Token，并且只把它放入相应子进程的 `GH_TOKEN`。AI 创建或维护 PR 时使用 `scripts/pr-bot.sh`，不以环境中的 Owner 登录直接执行 `gh pr create` 或同类 PR 修改命令。

**场景：App 验收后 Owner 登录仍可用**

- 条件：App 已通过验收，且 AI 环境中仍配置了 Owner `gh` 登录。
- 结果：机器人运行不需要注销该登录。
- 结果：每次机器人 API 调用都使用自身短期 App Installation Token，而不是环境中的 Owner 登录。

**场景：AI 通过机器人提交 PR**

- 条件：AI 为已经推送的开发分支创建或维护 PR。
- 结果：它调用 `scripts/pr-bot.sh`，而不是直接使用 Owner 身份修改 PR。
- 结果：只有当 PR 由已配置的 App 身份拥有或更新，并确认 `@cuihe500` 为被请求 Reviewer 时，流程才能进入审查。

**场景：机器人 Token 保持进程范围**

- 条件：机器人命令完成 GitHub API 操作。
- 结果：Installation Token 不会被输出、写入仓库或由 `gh auth login` 保存。
