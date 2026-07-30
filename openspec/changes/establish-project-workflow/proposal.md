## Why

当前开发流程从 OpenSpec 开始，缺少统一的需求入口、优先级、排期和全生命周期状态跟踪，导致 Issue、规格、分支和 PR 之间无法稳定追溯。Issue #2 要求将 GitHub Project 作为可见的流程状态源，并在每个门禁同步更新。

## What Changes

- 所有已确认需求先创建 GitHub Issue，并立即加入 `CloudPilot-PVE Development` Project。
- 在建立 OpenSpec 前设置 Priority 和 Iteration；没有排期的需求不得进入规格阶段。
- 定义 `Backlog → Planned → Spec → In Progress → Testing → In Review → Done` 状态流转及进入条件。
- OpenSpec、分支和 PR 必须关联同一个 Issue；PR 使用 `Closes #<issue>`，合并后自动关闭需求。
- 增加需求 Issue 模板并更新开发规范、仓库约束和 PR 模板。
- 初始化仓库 OpenSpec 目录及 Pi 的官方 OpenSpec 命令和 Skills。

## Capabilities

### New Capabilities

- `development-workflow`: 规定需求从 Issue 建立到 PR 合并期间的 Project 同步、追溯关系和流程门禁。

### Modified Capabilities

无。

## Impact

- GitHub：新增用户 Project #5、需求 Issue #2、状态/优先级/迭代字段及仓库关联。
- 仓库：修改 `AGENTS.md`、`docs/ai-development.md`、`.github/pull_request_template.md`，新增需求 Issue 模板和 OpenSpec 初始化文件。
- API、数据库、运行时代码和生产 PVE：无影响。
