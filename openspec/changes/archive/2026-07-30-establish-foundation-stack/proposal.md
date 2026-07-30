## Why

Issue [#7](https://github.com/cuihe500/CloudPilot-PVE/issues/7) requires the first runnable vertical slice so later product work has a verified API contract, frontend integration, and common build entry points. The repository currently contains documentation only and cannot start, test, or build an application.

## What Changes

- Add a Gin-based Go service with health and readiness endpoints.
- Add an OpenAPI 3.1 contract and generated TypeScript API types.
- Add a Vue 3, TypeScript, Vite, and Ant Design Vue web application that displays backend availability and a clear connection failure state.
- Standardize frontend dependency management on pnpm.
- Add root `make generate`, `make test`, `make check`, and `make build` commands.
- Add a minimal GitHub Actions workflow that runs the repository checks and build.
- Add the planned project-local Pi safety gate for protected paths and dangerous operations, with fail-closed behavior when confirmation is unavailable.
- Codify bilingual OpenSpec authoring with normative English followed by a non-normative Chinese translation that does not affect parsing or implementation.
- Update architecture and project documentation to replace the previous `net/http` and Element Plus choices with Gin and Ant Design Vue.

## Capabilities

### New Capabilities

- `application-foundation`: Covers service health/readiness behavior, typed frontend integration, reproducible build commands, the minimum CI baseline, and the project-local AI safety gate.

### Modified Capabilities

None.

## Impact

- Adds `cmd/cloudpilot`, `internal/httpapi`, `api/openapi.yaml`, `web`, root build files, a GitHub Actions workflow, and `.pi/extensions/safety-gate.ts`; updates OpenSpec and AI development rules.
- Adds Go dependencies for Gin and frontend dependencies for Vue, Vite, Ant Design Vue, OpenAPI type generation, and required checks.
- Changes the documented backend HTTP and frontend UI technology choices before any runtime API has been released.
- Does not add a database, authentication, background jobs, LLM access, PVE access, deployment, or production infrastructure changes.

---

## 中文翻译（非规范性）

> 本节仅为英文规范正文的翻译，不参与校验、实现或验收；如有歧义，以英文为准。

### 背景

Issue [#7](https://github.com/cuihe500/CloudPilot-PVE/issues/7) 要求建立首个可运行的纵向切片，为后续产品工作提供经过验证的 API 契约、前端集成和统一构建入口。仓库目前只有文档，尚不能启动、测试或构建应用。

### 变更内容

- 增加基于 Gin 的 Go 服务，并提供健康和就绪接口。
- 增加 OpenAPI 3.1 契约及由其生成的 TypeScript API 类型。
- 增加 Vue 3、TypeScript、Vite 和 Ant Design Vue Web 应用，用于展示后端可用状态和明确的连接失败状态。
- 统一使用 pnpm 管理前端依赖。
- 在根目录增加 `make generate`、`make test`、`make check` 和 `make build` 命令。
- 增加运行仓库检查和构建的最小 GitHub Actions 工作流。
- 增加计划中的项目级 Pi 安全门，用于保护路径和拦截危险操作；无法取得确认时失败关闭。
- 固化 OpenSpec 中英双语编写方式：英文规范正文在前，中文非规范翻译在后，且中文不影响解析或实现。
- 更新架构和项目文档，将原有 `net/http` 与 Element Plus 技术选择替换为 Gin 和 Ant Design Vue。

### 能力范围

**新增能力**

- `application-foundation`：涵盖服务健康与就绪行为、类型化前端集成、可复现构建命令、最小 CI 基线和项目级 AI 安全门。

**修改能力**

无。

### 影响

- 增加 `cmd/cloudpilot`、`internal/httpapi`、`api/openapi.yaml`、`web`、根目录构建文件、GitHub Actions 工作流和 `.pi/extensions/safety-gate.ts`；更新 OpenSpec 与 AI 开发规则。
- 增加 Gin 的 Go 依赖，以及 Vue、Vite、Ant Design Vue、OpenAPI 类型生成和必要检查所需的前端依赖。
- 在任何运行时 API 发布前，修改文档中的后端 HTTP 和前端 UI 技术选择。
- 不增加数据库、认证、后台任务、LLM 访问、PVE 访问、部署或生产基础设施变更。
