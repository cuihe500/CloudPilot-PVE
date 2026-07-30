## Context

仓库已有 OpenSpec、分支、验证和 PR 约束，但没有统一的需求入口，也没有跨阶段的可见状态。GitHub Project #5 已关联本仓库，Issue #2 是第一条按新流程管理的需求。

## Goals / Non-Goals

**Goals:**

- 使用一个 Issue 贯穿需求、OpenSpec、分支和 PR。
- 使用 Project Status、Priority、Iteration 表达当前阶段和排期。
- 每次进入下一阶段前同步 Project；同步失败时停止推进。
- 尽量使用 GitHub 内置工作流，避免维护额外自动化。

**Non-Goals:**

- 不把 PR 作为第二个 Project 事项。
- 不增加自定义 GitHub Action、机器人或外部项目管理服务。
- 不改变产品运行时代码、API、数据库或 PVE 行为。

## Decisions

### 一个需求只保留一个 Project 事项

Project 跟踪需求 Issue，PR 通过 `Closes #<issue>` 和 GitHub 的 linked pull requests 关联。这样合并后 Issue 自动关闭，并由 Project 内置工作流设为 `Done`，避免 Issue/PR 双卡片状态漂移。

### 使用七阶段状态模型

状态固定为 `Backlog → Planned → Spec → In Progress → Testing → In Review → Done`。Priority 使用 P0-P3，Iteration 使用从周一开始的两周期限。进入 `Spec` 前必须已有 Priority 和 Iteration。

### 人工/AI 门禁与内置自动化结合

Issue 创建时通过 `gh issue create --project` 加入 Project。语义阶段由执行任务的 AI 或开发者在进入阶段前更新，因为 GitHub 事件无法判断 OpenSpec 是否批准或测试是否完成。Issue 关闭到 `Done` 使用 Project 内置工作流。状态同步失败时不得继续后续操作。

### 仓库文档即执行约束

`AGENTS.md` 定义不可跳过的流程，`docs/ai-development.md` 提供命令和阶段说明，Issue/PR 模板强制留下关联信息。OpenSpec 官方 Pi 资源由 `openspec init --tools pi` 生成并纳入版本控制。

## Risks / Trade-offs

- [中间状态依赖执行者更新] → 把更新动作设为进入下一阶段的门禁，并在 PR 模板复核。
- [个人 Project 的编号或字段 ID 未来变化] → 文档使用稳定的 Project URL/名称，不把字段 ID 写入仓库。
- [GitHub 内置工作流配置不随 Git 版本化] → 在开发文档记录期望配置，并通过只读 CLI 检查字段和事项状态。
- [OpenSpec 初始化生成多份 Pi 文件] → 保留官方生成文件，不建立自定义包装层。

## Migration Plan

1. 创建并配置 Project #5，关联仓库。
2. 创建 Issue #2，设置 P1、Iteration 1 并按阶段流转。
3. 初始化 OpenSpec，提交本提案和规范。
4. 更新仓库约束、开发文档和模板。
5. 合并 PR 后由 `Closes #2` 关闭 Issue，确认 Project 为 `Done`。

回滚时可回退仓库提交并关闭 Project；Issue 和 PR 历史保留，不删除审计记录。

## Open Questions

无。
