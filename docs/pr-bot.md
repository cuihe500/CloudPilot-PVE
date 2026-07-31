# CloudPilot PVE PR Bot

`CloudPilot PVE PR Bot` 是本仓库专用的 GitHub App。它只编排 Pull Request，使 AI 创建的 PR 可以由项目 Owner `@cuihe500` 独立审查。

初始实现：Issue #3；OpenSpec：[`setup-pr-bot`](../openspec/changes/archive/2026-07-30-setup-pr-bot/)。
当前提交流程与凭据策略：Issue #14；OpenSpec change：`clarify-pr-bot-auth-coexistence`。

## 功能边界

允许：

- 读取当前仓库、分支、提交和 PR 元数据。
- 从已经推送的开发分支创建目标为 `main` 的 Draft PR。
- 校验并更新机器人自己创建的 PR 标题和正文。
- 请求并确认 `@cuihe500` Reviewer。
- Reviewer 确认后将 Draft 标记为 Ready。
- 查询机器人创建的 PR 状态。

禁止：

- 创建、修改或推送代码。
- 合并、关闭、批准或驳回 PR。
- 删除分支。
- 修改仓库设置、Actions、Secrets 或部署。
- 操作其他仓库或 PVE。

GitHub App 只拥有：

```text
Metadata: read
Contents: read
Pull requests: write
```

## 文件

```text
scripts/pr-bot-manifest.json   可审查的 GitHub App Manifest
scripts/pr-bot.sh              注册、验证和 PR 编排 CLI
scripts/pr-bot_test.sh         使用假 gh 的失败关闭测试
```

秘密不进入仓库：

```text
~/.config/cloudpilot-pve-pr-bot/
├── private-key.pem   # 0600
└── config.json       # 0600
```

`config.json` 仅保存 App ID、Installation ID、App slug 和固定仓库身份。私钥用于生成最长约 10 分钟的 App JWT，再交换约 1 小时有效的 Installation Token。Token 只通过子进程 `GH_TOKEN` 使用，不写入 `gh auth`。

## 首次注册

首次注册必须由当前 Owner 完成两次网页确认。全部操作应在一小时内完成。

### 1. 生成注册页

```bash
./scripts/pr-bot.sh registration-page
```

命令生成权限为 `0600` 的临时 HTML 文件和一次性 state。将 HTML 安全复制到 Owner 的本地机器并在已登录 GitHub 的浏览器中打开，然后点击注册按钮。

GitHub 显示的配置必须是：

- 名称：`CloudPilot PVE PR Bot`
- 私有 App，仅可安装在当前账号
- Webhook：禁用
- OAuth / Device Flow：禁用
- Contents：Read-only
- Pull requests：Read & write
- 其他权限：No access

确认创建后，浏览器会返回仓库页面，地址栏包含一次性 `code` 和 `state`。

### 2. 转换 Manifest

```bash
./scripts/pr-bot.sh convert '<code>' '<state>'
```

命令验证 state，通过当前 Owner 的 `gh` 登录转换 code，将私钥写入用户配置目录，并输出 App 安装地址。code 只能使用一次，不应写入仓库或日志。

### 3. 安装并限定仓库

打开命令输出的安装地址，选择：

```text
Only select repositories
→ CloudPilot-PVE
```

不要选择 `All repositories`。

安装完成后运行：

```bash
./scripts/pr-bot.sh finalize
./scripts/pr-bot.sh verify
```

`finalize` 只接受 Owner 为 `cuihe500`、安装模式为 `selected`、且安装仓库恰好为 `cuihe500/CloudPilot-PVE` 的安装。

## 使用机器人提交 PR

### 身份边界与前置条件

- 机器人是 AI 创建或维护 PR 时的唯一 PR 身份；它不会创建、修改或推送代码。源分支必须先由正常 Git 流程推送到远端，且相对 `main` 有提交。
- Owner 的 `gh` 登录可以保留并与机器人共存。机器人每次 GitHub API 调用都会生成新的短期 Installation Token，并仅通过对应 `gh` 子进程的 `GH_TOKEN` 使用它；Token 不写入 `gh auth`。
- AI 不得使用环境中的 Owner 登录执行 `gh pr create`、直接 `gh api` PR 修改，或其他等效的 PR 创建、更新、请求审查命令。必须调用本脚本。
- 在开始前，完成对应 Issue / Project / OpenSpec、代码审查和验证；机器人只负责 PR 编排，不管理 Issue 或 Project 状态。

### 1. 推送分支并验证机器人

在提交已经完成、工作树符合项目流程后执行：

```bash
git status --short
branch="$(git branch --show-current)"
test "$branch" != main
git push -u origin HEAD
./scripts/pr-bot.sh verify
```

`verify` 检查私钥与配置文件权限、App slug、Owner、仓库、安装范围和最小权限。任何检查失败时停止；不要退回到 Owner 身份直接创建 PR。

### 2. 准备完整 PR 正文

将所有尖括号中的说明替换为真实内容后，写入仓库外的临时文件。机器人拒绝缺少章节、空章节或未解析模板注释的正文：

```bash
cat >/tmp/pr-body.md <<'EOF'
## 关联
- Issue：Closes #<issue-number>
- OpenSpec：`openspec/changes/<change-id>/`

## 背景与目标
<为什么需要这项变更>

## 修改内容
- <实际修改项>

## 验证
- <实际运行的命令及结果>

## 安全与风险
- 安全影响：<影响或“无”>
- 回滚方式：<明确方式>
- 已知风险：<风险或“无”>

## 契约、数据与配置
- <OpenAPI、迁移和配置影响或“不适用”>

## 界面证据
<截图、录屏或“无 UI 变化”>

## 未完成项
<明确延期项或“无”>
EOF
```

没有对应 Issue 或 OpenSpec 的小型非行为变更，正文仍须填写 `N/A` 及原因；其余章节仍必须非空。

### 3. 创建或恢复机器人拥有的 PR

```bash
./scripts/pr-bot.sh create \
  --head "$branch" \
  --title '<type>: <short summary>' \
  --body-file /tmp/pr-body.md
```

固定流程为：验证 App、安装、权限、仓库、远端分支、相对 `main` 的 diff 和正文；创建 Draft PR，或仅恢复同一机器人创建的同源 PR；请求并重新读取 `@cuihe500` Reviewer；确认成功后将 Draft 标记为 Ready。成功时命令输出 PR URL。

机器人不会接管其他身份创建的开放 PR，也不会关闭 PR、删除分支或合并。若同一分支已有其他身份的开放 PR，命令会失败且不修改该 PR；由 Owner 处理冲突后再继续，不得绕过机器人另建 Owner 作者的 PR。

### 4. 确认状态、失败恢复和后续流程

使用创建命令输出的编号查询机器人拥有的 PR：

```bash
./scripts/pr-bot.sh status <pr-number>
```

输出必须显示 `state` 为 `open`、机器人作者、`@cuihe500` 位于 `requested_reviewers`，且 `draft` 为 `false` 才表示已 Ready。Reviewer 请求或 Ready 转换失败时，已创建 PR 保持 Draft；修正配置、正文或 GitHub 侧阻塞条件后，使用相同 `create` 命令重试，机器人会安全恢复自己的开放 PR。

PR 创建并验证后，按 `AGENTS.md` 将关联 Issue 的 Project 项目更新为 `In Review`。机器人没有 Issues 或 Projects 权限；它不能代替这项流程同步、Owner 审查或合并门禁。

## Owner 登录与机器人凭据共存

App 验收后**不要求**执行 `gh auth logout`。Owner 的 `gh` 登录可继续用于 Owner 的人工操作；它不会成为机器人的 PR 身份，也不能替代 `@cuihe500` 的独立 Review。

机器人 App 私钥仍只保存在 `~/.config/cloudpilot-pve-pr-bot/private-key.pem`（`0600`），`config.json` 仍为 `0600`。每个机器人命令重新签发最长约 10 分钟的 App JWT，再交换约 1 小时有效的 Installation Token，并只在相应子进程环境中传递。不要打印、复制、提交或通过 `gh auth login` 保存这些凭据。

## 密钥轮换与撤销

怀疑私钥泄露时：

1. 在 GitHub App 设置中撤销旧私钥并生成新私钥。
2. 将新私钥安全写入 `private-key.pem` 并设置 `0600`。
3. 运行 `./scripts/pr-bot.sh verify`。
4. 检查 GitHub 审计日志中的异常 PR 操作。

停止机器人时，应先 Suspend 或 Uninstall 安装，再删除本地私钥。不要通过降低 `main` 分支保护来恢复工作。
