## 关联

- Issue：Closes #<!-- issue number；不适用时填写 N/A 和原因 -->
- OpenSpec：`openspec/changes/<!-- change-id -->/` <!-- 不适用时填写 N/A 和原因 -->
- Project：[`CloudPilot-PVE Development`](https://github.com/users/cuihe500/projects/5)，有对应 Issue 时状态应为 `In Review`

## 背景与目标

<!-- 为什么需要此次变更？ -->

## 修改内容

<!-- 按组件列出实际修改，不要只复制提交标题。 -->

- <!-- 修改项 -->

## 验证

<!-- 只填写实际运行过的命令和结果；未运行项必须说明原因。 -->

- [ ] 针对性测试：
- [ ] `make check`：
- [ ] `make build`：
- [ ] 手工验证：

## 安全与风险

<!-- 说明权限、审批、配额、数据、PVE、凭据、回滚和兼容性影响；无影响时写“无”。 -->

- 安全影响：
- 回滚方式：
- 已知风险：

## 契约、数据与配置

- [ ] OpenAPI 无变化，或已同步契约和生成代码
- [ ] 数据库无变化，或已添加并验证迁移
- [ ] 配置/环境变量无变化，或已更新文档和示例

## 界面证据

<!-- 有 UI 变化时提供截图或录屏；无 UI 变化时写“无”。 -->

无。

## 未完成项

<!-- 明确延期内容；没有则写“无”。 -->

无。

## 提交前检查

- [ ] 分支从最新 `main` 创建，PR 目标为 `main`
- [ ] 有对应 Issue 时，已设置 Priority、Iteration，且 Project 状态为 `In Review`
- [ ] Reviewers 已包含项目 Owner `@cuihe500`
- [ ] 已阅读并遵守 `AGENTS.md` 和相关 OpenSpec
- [ ] 当前变更不包含秘密、临时文件或无关重构
- [ ] 已执行 `/review` 或等价只读审查
- [ ] PR 正文准确覆盖本次全部修改
