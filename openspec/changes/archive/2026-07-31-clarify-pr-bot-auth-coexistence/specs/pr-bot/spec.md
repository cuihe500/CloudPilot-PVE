## ADDED Requirements

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

## REMOVED Requirements

### Requirement: Owner credential isolation

**Reason**: The Owner explicitly approved coexistence of the ambient Owner `gh` login and the PR Bot credentials. The bot already uses short-lived installation tokens through a per-process `GH_TOKEN` override, so mandatory Owner logout is not required to preserve the bot identity boundary.

**Migration**: Retain an existing Owner `gh` login when needed for Owner operations. Use `scripts/pr-bot.sh` for every AI-authored PR creation or maintenance operation so that the App installation token, rather than ambient Owner authentication, is used.

## 中文翻译（非规范性）

### 新的凭据共存规则

App 通过验收后，AI 环境可以继续保留 Owner 的 `gh` 登录。机器人每次创建、更新、请求审查或读取机器人拥有的 PR 时，都重新获取短期 App Installation Token，并且只把它放入相应子进程的 `GH_TOKEN`。AI 创建或维护 PR 时使用 `scripts/pr-bot.sh`，不以环境中的 Owner 登录直接执行 `gh pr create` 或同类 PR 修改命令。

当 App 验收完成且 Owner 登录仍然存在时，不需要为了机器人运行而注销该登录；机器人调用仍会使用自身短期 Token。AI 处理已经推送的开发分支时，通过机器人命令提交或维护 PR，结果 PR 仅由已配置的 App 身份创建或更新，并在确认 `@cuihe500` 为审查人后进入审查流程。每次机器人命令结束后，Installation Token 不会输出、写入仓库或由 `gh auth login` 保存。

### 被替换的旧规则

旧的“Owner 凭据隔离”规则被替换，原因是 Owner 已明确同意两种凭据共存，且机器人使用逐进程的短期 `GH_TOKEN` 保持自身身份边界。迁移时可保留 Owner 登录供 Owner 操作使用；所有 AI PR 创建或维护操作继续通过 `scripts/pr-bot.sh`，以确保使用 App Installation Token 而非环境身份。
