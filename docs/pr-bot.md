# CloudPilot PVE PR Bot

`CloudPilot PVE PR Bot` 是本仓库专用的 GitHub App。它只编排 Pull Request，使 AI 创建的 PR 可以由项目 Owner `@cuihe500` 独立审查。

关联需求：Issue #3；OpenSpec：[`setup-pr-bot`](../openspec/changes/archive/2026-07-30-setup-pr-bot/)。

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

## 创建 PR

源分支必须已经推送。PR 正文必须包含以下非空章节：

```text
## 关联（必须包含 Issue 和 OpenSpec）
## 背景与目标
## 修改内容
## 验证
## 安全与风险
## 契约、数据与配置
## 界面证据
## 未完成项
```

执行：

```bash
./scripts/pr-bot.sh create \
  --head feat/example \
  --title 'feat: example change' \
  --body-file /tmp/pr-body.md
```

流程固定为：

1. 验证 App、安装、权限、仓库、分支、diff 和正文。
2. 创建 Draft PR，或恢复同一机器人创建的现有 Draft。
3. 请求 `@cuihe500` Reviewer。
4. 从 GitHub 重新读取并确认 Reviewer。
5. 确认后转为 Ready。

任何步骤失败都返回非零退出码。已创建的 PR 保持 Draft；机器人不会关闭 PR 或删除分支。

查询状态：

```bash
./scripts/pr-bot.sh status <pr-number>
```

该命令拒绝查询并声明管理其他身份创建的 PR。

## Owner 审查隔离

机器人通过真实 PR 验收后，必须从 AI/pi 环境移除 Owner 的 `gh` 登录：

```bash
gh auth logout --hostname github.com --user cuihe500
```

此操作只在所有验收检查完成后执行。Owner 后续在独立浏览器或人工终端中 Review 和 Merge。不要把 Owner Token 重新注入 AI 会话。

## 密钥轮换与撤销

怀疑私钥泄露时：

1. 在 GitHub App 设置中撤销旧私钥并生成新私钥。
2. 将新私钥安全写入 `private-key.pem` 并设置 `0600`。
3. 运行 `./scripts/pr-bot.sh verify`。
4. 检查 GitHub 审计日志中的异常 PR 操作。

停止机器人时，应先 Suspend 或 Uninstall 安装，再删除本地私钥。不要通过降低 `main` 分支保护来恢复工作。
