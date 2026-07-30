# CloudPilot-PVE

> 不是把 PVE 面板搬进聊天框，而是把运维工单变成安全变更。

AI 原生的 Proxmox VE 运维平台。通过自然语言完成虚拟机与 LXC 的申请、审批、交付和回收，并提供审批、审计和安全执行能力。

面向中小团队、学校实验室和私有云的 Proxmox AI 自助服务门户。

## 为什么不是又一个 PVE 面板

统一监控（Pulse、Prometheus/Grafana）、多集群面板（PveSphere、官方 PDM）、AI 操作（各类 Proxmox MCP 项目）三个赛道都已成熟。单纯的「AI 对话」和「MCP」无法成为护城河。

真正的差异在：**权限、审批、配额、资源归属、有效期、审计和回收。**

本平台不只服务运维管理员，还服务**资源申请者**和**审批人**——把自然语言资源申请转换成可预览、可审批、可审计、可回滚的基础设施变更。

## 典型场景

> 「给测试组创建 3 台 Ubuntu 24.04，4C8G，使用测试网络，7 天后自动回收。」

## 黄金路径

```
理解需求 → 检查配额/容量 → 生成变更计划 → 人工确认 → 克隆模板
       → Cloud-init → 健康验证 → 交付账号/IP → 到期回收
```

## 设计原则

- **AI 只负责理解**：把自然语言转换成经过校验的结构化请求。
- **确定性代码负责执行**：权限判断、配额校验、实际变更全部由代码完成。
- **不允许模型直接执行任意命令**：没有 SSH 通道暴露给 LLM。

## 技术方案

- 前端：Vue 3、TypeScript、Vite、Ant Design Vue，使用 pnpm 管理依赖
- 后端：Go、Gin、PostgreSQL、`pgx`、`sqlc`
- 后台任务：River，复用 PostgreSQL 承载持久化任务
- 接口契约：OpenAPI 3.1，生成 Go 与 TypeScript 类型
- AI：单模型 Structured Outputs，确定性代码完成校验和执行
- PVE：最小权限 API Token，仅封装黄金路径所需 REST API
- 入口与部署：Nginx + Docker Compose/systemd
- AI 开发：pi CLI + OpenSpec + 项目级 Skills/Prompts + CI 质量门禁

详细决策见[架构说明](docs/architecture.md)。

## 最小 MVP 范围

只做一条完整黄金路径：

- 单个 PVE 集群
- 基于现有模板创建 VM/LXC
- Web 对话入口
- 结构化变更预览与二次确认
- 申请人、用途、配额与到期时间
- 执行状态、结果验证与审计记录
- 到期提醒与自动回收

## 明确不做

- 自研时序监控和完整仪表盘（深度监控直接接 Pulse / Prometheus / PVE·PDM）
- 任意命令执行
- 自主故障修复
- 全量 PVE API 覆盖
- 多模型市场、插件系统、手机 App
- 第一版多集群

监控在本平台只作为 AI 决策和执行验证的上下文，不重复造轮子。

## 商业化设想

单集群核心流程开源；多集群、SSO/RBAC、飞书/钉钉/企微审批、策略中心和合规审计作为付费能力。

## 文档

- [架构说明](docs/architecture.md)：技术栈、组件边界、数据流、安全和部署。
- [AI 主导开发规范](docs/ai-development.md)：OpenSpec、pi CLI、质量门禁和人工确认点。
- [AI 开发约束](AGENTS.md)：所有 AI 编码工具必须遵守的仓库级规则。
- [PR 机器人](docs/pr-bot.md)：专用 GitHub App 的权限边界、安装和使用方式。

## 当前状态

基础运行框架已建立：Gin 提供健康与就绪 API，Vue 页面通过 OpenAPI 生成类型展示后端状态。数据库、认证、任务队列、LLM、PVE 和业务黄金路径尚未实现。
