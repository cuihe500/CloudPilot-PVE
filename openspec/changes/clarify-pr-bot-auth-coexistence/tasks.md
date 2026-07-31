## 1. Documentation and Current Specification

- [x] 1.1 Update `docs/pr-bot.md` and the shared PR command in `docs/ai-development.md` with an end-to-end, copyable PR Bot submission guide covering preflight, PR-body preparation, `verify`, `create`, status inspection, Ready transition, and fail-closed recovery.
- [x] 1.2 Replace the mandatory Owner `gh` logout guidance with credential-coexistence guidance that preserves short-lived, process-scoped App installation tokens and forbids direct Owner-authenticated AI PR mutations.
- [x] 1.3 Synchronize the approved `pr-bot` delta specification into `openspec/specs/pr-bot/spec.md` without changing App permissions, branch protection, or prohibited-operation boundaries.

## 2. Validation and Delivery

- [x] 2.1 Run `./scripts/pr-bot.sh verify` and `bash scripts/pr-bot_test.sh` to confirm the existing bot configuration and fail-closed command behavior remain intact.
- [x] 2.2 Validate the OpenSpec change, Markdown links, shell syntax, and documentation diff; run `make check` as the repository-wide gate.
- [x] 2.3 Perform a read-only review for secret exposure, direct Owner-authenticated PR commands, unintended historical-artifact edits, and consistency between the guide and the current `pr-bot` specification.
- [ ] 2.4 Commit the scoped change, push its branch, use the PR Bot to create a PR with `Closes #14`, and move the Project item to `In Review` after verification passes.

## 中文翻译（非规范性）

### 文档与现行规范

第一组工作会把 `docs/pr-bot.md` 补充为可直接执行的 PR Bot 提交流程，并将 `docs/ai-development.md` 中的共享 AI PR 命令改为调用机器人。流程涵盖前置检查、PR 正文准备、`verify`、`create`、状态查询、Ready 转换和失败关闭后的恢复方式。文档将以凭据共存说明替换强制注销 Owner `gh` 的说明，同时保持短期、仅限进程的 App Installation Token，并禁止 AI 以 Owner 身份直接修改 PR。获批后的 `pr-bot` 增量规范会同步到 `openspec/specs/pr-bot/spec.md`，不改变 App 权限、分支保护或禁止操作边界。

### 验证与交付

第二组工作会验证既有机器人配置和失败关闭行为，检查 OpenSpec、Markdown 链接、Shell 语法和文档差异，并执行 `make check`。随后进行只读复核，重点检查秘密暴露、直接使用 Owner 身份的 PR 命令、误改历史归档产物，以及指南与现行 `pr-bot` 规范的一致性。验证通过后，将提交并推送该分支，使用 PR Bot 创建关联 Issue #14 的 PR，并把 Project 项目更新为 `In Review`。
