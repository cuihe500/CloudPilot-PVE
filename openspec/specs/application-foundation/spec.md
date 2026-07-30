# application-foundation Specification

## Purpose

Define the runnable application baseline, operational health behavior, typed frontend integration, unified automation, CI, AI safety gate, bilingual OpenSpec convention, and documented technology choices.

## Requirements

### Requirement: Service liveness and readiness
The backend SHALL expose `GET /api/healthz` and `GET /api/readyz` as unauthenticated operational endpoints defined by the OpenAPI contract. Each successful response SHALL use JSON, return HTTP 200, and contain a stable status value. Liveness SHALL not depend on external services; readiness SHALL reflect all dependencies required by the currently configured application.

#### Scenario: Process is healthy
- **WHEN** a client sends `GET /api/healthz` to a running service
- **THEN** the service returns HTTP 200 with the contract-defined JSON success response

#### Scenario: Foundation service is ready
- **WHEN** a client sends `GET /api/readyz` before any required external dependency has been configured
- **THEN** the service returns HTTP 200 with the contract-defined JSON ready response

### Requirement: Typed frontend health integration
The web application SHALL use TypeScript types generated from `api/openapi.yaml` when requesting backend health. It SHALL display an explicit loading state while checking, a success state for a contract-valid successful response, and a clear non-sensitive error state when the backend cannot be reached or does not return success.

#### Scenario: Backend is available
- **WHEN** the web application receives a contract-valid successful health response
- **THEN** it displays that the backend is available

#### Scenario: Backend is unavailable
- **WHEN** the health request fails or returns a non-success response
- **THEN** the web application displays a clear backend connection failure without exposing internal details or secrets

### Requirement: Contract generation is reproducible
The repository SHALL generate committed frontend API types from the OpenAPI document through pnpm-managed tooling. Generated types SHALL NOT be edited manually, and the unified check SHALL fail when regeneration produces an uncommitted difference.

#### Scenario: Contract and generated types agree
- **WHEN** a contributor runs `make generate` from a clean checkout with dependencies installed
- **THEN** the generated TypeScript API declaration matches the committed file without unrelated changes

#### Scenario: Generated types are stale
- **WHEN** the OpenAPI document changes without updating the committed generated TypeScript declaration
- **THEN** `make check` fails on the generated-file consistency check

### Requirement: Unified repository commands
The repository SHALL provide root `make generate`, `make test`, `make check`, and `make build` targets as the supported automation interface. The commands SHALL cover the Go service and Vue application where applicable and SHALL return a non-zero status when an invoked operation fails.

#### Scenario: Repository checks pass
- **WHEN** a contributor runs `make check` in a correctly provisioned clean checkout
- **THEN** formatting, static analysis, contract consistency, type checking, linting, and automated tests complete successfully

#### Scenario: Application builds
- **WHEN** a contributor runs `make build` in a correctly provisioned clean checkout
- **THEN** the Go service binary and production frontend assets are produced successfully

### Requirement: Pull request CI baseline
The repository SHALL run the unified checks and build in GitHub Actions for proposed changes. CI SHALL install the declared Go and pnpm toolchains and invoke root Make targets rather than maintaining separate build logic.

#### Scenario: Proposed change passes CI
- **WHEN** a pull request contains a valid backend, frontend, contract, or build change
- **THEN** GitHub Actions completes `make check` and `make build` successfully

#### Scenario: Proposed change breaks a required check
- **WHEN** a pull request causes a unified check or build command to fail
- **THEN** the GitHub Actions job fails and prevents the change from satisfying the project completion gate

### Requirement: Project-local AI safety gate
The repository SHALL provide an auto-discovered project-local Pi extension that inspects mutating tool calls before execution. The extension SHALL block direct edits to environment files, credential paths, private keys, and committed generated API types. It SHALL block operations prohibited by project policy and SHALL require explicit interactive confirmation for destructive commands, destructive migrations, deployment, branch deletion, and production PVE access. A denied or unavailable confirmation SHALL fail closed.

#### Scenario: Protected file write is attempted
- **WHEN** an AI tool attempts to write or edit a protected credential, environment, private-key, or generated API type path
- **THEN** the safety gate blocks the tool call before the file is changed

#### Scenario: Prohibited Git operation is attempted
- **WHEN** an AI tool attempts a force push or destructive Git reset
- **THEN** the safety gate blocks the command without executing it

#### Scenario: Confirmation-gated operation is approved
- **WHEN** an AI tool requests a confirmation-gated operation in an interactive session and the human explicitly approves it
- **THEN** the safety gate allows that tool call to continue

#### Scenario: Confirmation is denied or unavailable
- **WHEN** a confirmation-gated operation is denied, times out, or runs without confirmation UI
- **THEN** the safety gate blocks the tool call before execution

#### Scenario: Ordinary development operation is requested
- **WHEN** an AI tool requests an operation that matches neither a protected path nor a dangerous command category
- **THEN** the safety gate does not block the tool call

### Requirement: Bilingual OpenSpec artifacts
The repository SHALL configure and document all new or updated OpenSpec planning artifacts as complete normative English followed by a complete non-normative Chinese translation. English SHALL be the sole source for validation, implementation, and acceptance. Chinese translations MUST NOT use syntax that OpenSpec parses as additional operations, requirements, scenarios, or task checkboxes, and MUST NOT add, remove, or alter the English meaning.

#### Scenario: A planning artifact is created or updated
- **WHEN** a contributor creates or updates an OpenSpec proposal, design, specification, or task artifact
- **THEN** the artifact contains the complete normative English content first and a complete Chinese translation under `## 中文翻译（非规范性）`

#### Scenario: Translation conflicts with normative text
- **WHEN** English and Chinese content can be interpreted differently
- **THEN** validation, implementation, and acceptance use the English content only

#### Scenario: OpenSpec parses translated content
- **WHEN** OpenSpec validates or reports status for a bilingual change
- **THEN** the Chinese translation creates no additional requirements, scenarios, or tracked tasks

### Requirement: Foundation technology choices are documented
The architecture and project overview SHALL identify Gin as the backend HTTP framework, Vue 3 with Ant Design Vue as the frontend stack, and pnpm as the frontend package manager. Documentation SHALL retain the existing monolith, OpenAPI-first, and no-direct-PVE-access boundaries.

#### Scenario: Contributor reviews the technology baseline
- **WHEN** a contributor reads the project overview and architecture documentation
- **THEN** the documented framework and package-manager choices match the runnable foundation without weakening existing security boundaries

---

## 中文翻译（非规范性）

> 本节仅为英文规范正文的翻译，不参与 OpenSpec 解析、校验、实现或验收；如有歧义，以英文为准。

**目的**

定义可运行应用基线、运维健康行为、类型化前端集成、统一自动化、CI、AI 安全门、OpenSpec 双语约定和文档化技术选择。

**需求一：服务存活与就绪**

后端提供无需认证的 `GET /api/healthz` 和 `GET /api/readyz` 运维接口，并由 OpenAPI 契约定义。每个成功响应使用 JSON、返回 HTTP 200，并包含稳定的状态值。存活状态不依赖外部服务；就绪状态反映当前配置应用所需的全部依赖。

**场景：进程健康**

- 条件：客户端向运行中的服务发送 `GET /api/healthz`。
- 结果：服务返回 HTTP 200 和契约定义的 JSON 成功响应。

**场景：基础服务就绪**

- 条件：尚未配置任何必需外部依赖时，客户端发送 `GET /api/readyz`。
- 结果：服务返回 HTTP 200 和契约定义的 JSON 就绪响应。

**需求二：类型化前端健康集成**

Web 应用在请求后端健康状态时使用由 `api/openapi.yaml` 生成的 TypeScript 类型。检查期间显示明确的加载状态；收到符合契约的成功响应时显示成功状态；后端无法连接或未返回成功时显示清晰且不含敏感信息的错误状态。

**场景：后端可用**

- 条件：Web 应用收到符合契约的健康成功响应。
- 结果：页面显示后端可用。

**场景：后端不可用**

- 条件：健康请求失败或返回非成功响应。
- 结果：页面显示明确的后端连接失败，且不暴露内部细节或秘密。

**需求三：契约生成可复现**

仓库通过 pnpm 管理的工具，根据 OpenAPI 文档生成并提交前端 API 类型。生成类型不得手工修改；重新生成产生未提交差异时，统一检查失败。

**场景：契约与生成类型一致**

- 条件：贡献者在依赖已安装的干净检出中运行 `make generate`。
- 结果：生成的 TypeScript API 声明与已提交文件一致，且没有无关变更。

**场景：生成类型过期**

- 条件：OpenAPI 文档已改变，但已提交的 TypeScript 声明未更新。
- 结果：`make check` 在生成文件一致性检查处失败。

**需求四：统一仓库命令**

仓库在根目录提供 `make generate`、`make test`、`make check` 和 `make build`，作为受支持的自动化入口。适用时命令同时覆盖 Go 服务和 Vue 应用；任何被调用操作失败时返回非零状态。

**场景：仓库检查通过**

- 条件：贡献者在工具配置正确的干净检出中运行 `make check`。
- 结果：格式、静态分析、契约一致性、类型检查、lint 和自动化测试全部成功。

**场景：应用构建成功**

- 条件：贡献者在工具配置正确的干净检出中运行 `make build`。
- 结果：成功生成 Go 服务二进制和生产前端资源。

**需求五：Pull Request CI 基线**

仓库通过 GitHub Actions 对拟议变更运行统一检查和构建。CI 安装声明的 Go 与 pnpm 工具链，并调用根目录 Make 目标，不另行维护重复的构建逻辑。

**场景：拟议变更通过 CI**

- 条件：Pull Request 包含有效的后端、前端、契约或构建变更。
- 结果：GitHub Actions 成功完成 `make check` 和 `make build`。

**场景：拟议变更破坏必要检查**

- 条件：Pull Request 导致统一检查或构建命令失败。
- 结果：GitHub Actions Job 失败，该变更不能满足项目完成门禁。

**需求六：项目级 AI 安全门**

仓库提供一个可自动发现的项目级 Pi Extension，在执行前检查会产生修改的工具调用。Extension 阻止直接修改环境文件、凭据路径、私钥和已提交的生成 API 类型；阻止项目策略禁止的操作；对破坏性命令、破坏性迁移、部署、删除分支和访问生产 PVE 要求明确的交互式确认。确认被拒绝或无法取得时失败关闭。

**场景：尝试写入受保护文件**

- 条件：AI 工具尝试 write 或 edit 受保护的凭据、环境、私钥或生成 API 类型路径。
- 结果：安全门在文件改变前阻止工具调用。

**场景：尝试禁止的 Git 操作**

- 条件：AI 工具尝试强制推送或破坏性 Git reset。
- 结果：安全门在执行前阻止命令。

**场景：确认受控操作获得批准**

- 条件：AI 工具在交互式会话中请求需要确认的操作，且人工明确批准。
- 结果：安全门允许该工具调用继续。

**场景：确认被拒绝或不可用**

- 条件：需要确认的操作被拒绝、超时或运行在没有确认界面的模式中。
- 结果：安全门在执行前阻止工具调用。

**场景：请求普通开发操作**

- 条件：AI 工具请求的操作既不匹配受保护路径，也不属于危险命令类别。
- 结果：安全门不阻止该工具调用。

**需求七：OpenSpec 双语产物**

仓库配置并记录统一规则：所有新建或更新的 OpenSpec 规划产物，先提供完整的英文规范正文，再提供完整的中文非规范翻译。英文是校验、实现和验收的唯一依据。中文翻译不使用会被 OpenSpec 解析为额外操作、需求、场景或任务复选框的语法，也不新增、删除或改变英文含义。

**场景：创建或更新规划产物**

- 条件：贡献者创建或更新 OpenSpec proposal、design、specification 或 task 产物。
- 结果：产物先包含完整英文规范内容，再在 `## 中文翻译（非规范性）` 下提供完整中文翻译。

**场景：翻译与规范正文冲突**

- 条件：英文和中文内容可以被解释为不同含义。
- 结果：校验、实现和验收只使用英文内容。

**场景：OpenSpec 解析翻译内容**

- 条件：OpenSpec 校验双语变更或报告其状态。
- 结果：中文翻译不产生额外需求、场景或被跟踪任务。

**需求八：记录基础技术选择**

架构和项目概览文档标明 Gin 是后端 HTTP 框架，Vue 3 与 Ant Design Vue 是前端技术栈，pnpm 是前端包管理器。文档保留现有单体、OpenAPI 优先和禁止直连 PVE 的边界。

**场景：贡献者查阅技术基线**

- 条件：贡献者阅读项目概览和架构文档。
- 结果：文档中的框架与包管理器选择和可运行基础一致，且没有削弱既有安全边界。
