## Context

The repository has architecture and workflow documentation but no runtime code, API contract, package manifests, build entry points, or CI workflow. Issue #7 establishes only the first runnable vertical slice. The approved technology changes replace the documented `net/http` router and Element Plus choices with Gin and Ant Design Vue; the remaining monolith, trust-boundary, and OpenAPI-first constraints stay unchanged.

## Goals / Non-Goals

**Goals:**

- Start and stop a minimal Go service safely and expose deterministic liveness and readiness responses.
- Prove a typed browser-to-API path with a small Vue status page.
- Make generation, tests, checks, and builds reproducible locally and in CI.
- Add the repository's planned Pi safety gate before runtime implementation begins.
- Make English the normative OpenSpec source while retaining complete non-normative Chinese translations.
- Establish only the directories and dependencies required by this slice.

**Non-Goals:**

- Database access, migrations, authentication, authorization, sessions, CSRF, task queues, LLM integration, PVE integration, or business workflows.
- Docker, deployment, releases, a CI version matrix, or production operations.
- Interfaces, dependency injection, configuration frameworks, global state, or API abstractions for hypothetical future implementations.

## Decisions

### Gin handles routing; the Go standard library handles process concerns

`cmd/cloudpilot` will construct an `http.Server` with explicit timeouts and graceful shutdown, while `internal/httpapi` will construct the Gin engine and handlers. Gin is the approved routing framework; `log/slog`, `context`, signals, and server lifecycle remain standard-library concerns. This keeps the framework boundary small without recreating routing or middleware.

Alternative considered: bare `net/http`. It has fewer dependencies, but the Owner explicitly selected Gin as the project HTTP framework.

### Health endpoints are dependency-free in this slice

`GET /api/healthz` reports that the process can serve HTTP. `GET /api/readyz` reports readiness for the currently configured application. Because this change adds no required external dependency, both return a small JSON success response. Later database or worker changes must extend readiness with real deterministic checks rather than adding speculative interfaces now.

### OpenAPI is the frontend contract source

`api/openapi.yaml` will define both endpoints and their shared response schema. `openapi-typescript` will generate a committed TypeScript declaration consumed by `openapi-fetch`; no duplicate handwritten frontend DTO will be added. Vite will proxy `/api` to the local Go service, avoiding a separate development CORS policy.

Alternative considered: handwritten fetch response types. This is shorter initially but violates the repository's contract-first boundary and permits drift.

### The frontend is one local component, not an application framework layer

The Vue application will install Ant Design Vue and render one status view with loading, success, and connection-failure states. State remains in the component because there is no cross-page requirement. Vue Router and a global store are not added until a real second route or shared state requirement exists.

### Root Make targets are the single automation interface

- `make generate` regenerates the TypeScript API declaration.
- `make test` runs backend and frontend tests.
- `make check` verifies formatting, Go vet/tests, generated contract stability, TypeScript, and frontend lint/tests.
- `make build` builds the Go binary and frontend assets.

The frontend pins pnpm through `packageManager` and commits `pnpm-lock.yaml`. CI installs one Go version and one pinned pnpm version, then invokes only the root Make targets. It does not duplicate build logic or add a version matrix.

### Minimal tests follow the behavior boundaries

A Go HTTP test will cover the health endpoints and response contract. A small frontend component test will cover successful and failed health requests. No broad fixture or mocking framework beyond the existing Vue/Vitest ecosystem will be introduced.

### A project-local Pi extension enforces the existing safety policy

`.pi/extensions/safety-gate.ts` will use Pi's `tool_call` interception API. It will block direct `write` and `edit` calls targeting environment files, credential paths, private keys, or the committed generated API declaration. It will also intercept dangerous `bash` operations such as recursive deletion, privilege escalation, destructive Git commands, force pushes, production PVE access, destructive migrations, and deployment commands.

Operations that project policy allows only after human confirmation will use `ctx.ui.confirm`; denial, timeout, or a mode without confirmation UI will block the tool call. Operations that project policy forbids outright will always block. Path comparisons will resolve against `ctx.cwd` rather than relying only on substring matching. Pattern classification will be exported as small pure functions and tested without executing dangerous commands. The extension will use only Node built-ins and Pi's extension API.

Alternative considered: rely on prompt instructions alone. Existing project documentation explicitly requires a hard interception layer because prompts cannot enforce safety boundaries.

### OpenSpec keeps normative English separate from Chinese translation

Every new or updated proposal, design, specification, and task artifact will place the complete normative English content first and append a complete Chinese translation under `## 中文翻译（非规范性）`. English alone drives OpenSpec validation, implementation, and acceptance. Specification translations will avoid OpenSpec operation, requirement, scenario, SHALL/MUST, WHEN, and THEN syntax; task translations will avoid checkbox syntax. Repository-level OpenSpec rules and AI development documentation will preserve this convention for later changes.

Alternative considered: duplicate the full OpenSpec syntax in both languages. That would make translated requirements and tasks parse as additional development inputs and create two competing sources of truth.

## Risks / Trade-offs

- [Gin and Ant Design Vue increase dependency surface] → Pin dependencies in Go and pnpm lockfiles and run the minimum repository checks in CI.
- [Readiness has no external dependency to distinguish it from liveness] → Keep the response honest for the current process and extend it only when a required dependency is introduced.
- [Committed generated types can drift] → Run generation followed by a clean-diff check in `make check` and CI.
- [The first CI workflow does not cover production deployment or multiple toolchain versions] → Keep the baseline fast; add matrices or deployment only when compatibility or delivery requirements exist.
- [Command matching cannot parse every possible shell construction] → Cover the shared dangerous forms, resolve protected paths, test rejection paths, fail closed without UI, and keep production credentials unavailable to the agent regardless of this defense-in-depth extension.
- [An overbroad gate can block legitimate generation] → Protect generated files from direct edit/write calls while allowing the reviewed `make generate` command.
- [English and Chinese text can diverge] → Treat English as the only normative source and require a complete non-normative translation in the same artifact.
- [Changing documented framework choices affects future implementation guidance] → Update README and architecture documentation in the same change.

---

## 中文翻译（非规范性）

> 本节仅为英文规范正文的翻译，不参与校验、实现或验收；如有歧义，以英文为准。

### 背景

仓库已有架构和流程文档，但没有运行时代码、API 契约、包清单、构建入口或 CI 工作流。Issue #7 只建立首个可运行的纵向切片。已批准的技术调整把文档中的 `net/http` 路由和 Element Plus 替换为 Gin 和 Ant Design Vue；其余单体、信任边界和 OpenAPI 优先约束保持不变。

### 目标与非目标

**目标**

- 安全启动和停止最小 Go 服务，并提供确定性的存活与就绪响应。
- 使用小型 Vue 状态页面证明浏览器到 API 的类型化调用路径。
- 使生成、测试、检查和构建在本地与 CI 中均可复现。
- 在实现运行时代码前增加仓库计划中的 Pi 安全门。
- 将英文作为 OpenSpec 规范来源，同时保留完整的中文非规范翻译。
- 只建立当前纵向切片必需的目录和依赖。

**非目标**

- 数据库访问、迁移、认证、授权、会话、CSRF、任务队列、LLM 集成、PVE 集成或业务流程。
- Docker、部署、发布、CI 版本矩阵或生产操作。
- 面向假设中未来实现的接口、依赖注入、配置框架、全局状态或 API 抽象。

### 技术决定

**Gin 负责路由，Go 标准库负责进程生命周期**

`cmd/cloudpilot` 使用具有明确超时和优雅关闭能力的 `http.Server`，`internal/httpapi` 负责构建 Gin 引擎和处理器。Gin 是已批准的路由框架；`log/slog`、`context`、信号和服务生命周期继续使用标准库。这样既不重复实现路由或中间件，也能保持较小的框架边界。

曾考虑直接使用 `net/http`。它依赖更少，但 Owner 已明确选择 Gin 作为项目 HTTP 框架。

**本次健康接口不依赖外部服务**

`GET /api/healthz` 表示进程能够提供 HTTP 服务。`GET /api/readyz` 表示当前配置下应用已经就绪。由于本次变更不增加必需的外部依赖，两个接口都返回小型 JSON 成功响应。以后引入数据库或 Worker 时，必须使用真实的确定性检查扩展就绪逻辑，而不是现在提前创建推测性接口。

**OpenAPI 是前端契约来源**

`api/openapi.yaml` 定义两个接口及其共享响应结构。`openapi-typescript` 生成提交到仓库的 TypeScript 声明，并由 `openapi-fetch` 使用；不增加重复的手写前端 DTO。Vite 将 `/api` 代理到本地 Go 服务，避免维护独立的开发环境 CORS 策略。

曾考虑手写 fetch 响应类型。它最初更短，但违反仓库的契约优先边界，并允许契约漂移。

**前端只包含一个本地组件，不建立额外应用框架层**

Vue 应用安装 Ant Design Vue，并渲染一个具有加载、成功和连接失败状态的页面。因为不存在跨页面需求，状态保留在组件内。在出现真实的第二个路由或共享状态需求前，不增加 Vue Router 和全局状态库。

**根目录 Make 目标是唯一自动化入口**

- `make generate` 重新生成 TypeScript API 声明。
- `make test` 运行后端和前端测试。
- `make check` 检查格式、Go vet/测试、生成契约一致性、TypeScript 及前端 lint/测试。
- `make build` 构建 Go 二进制和前端资源。

前端通过 `packageManager` 固定 pnpm，并提交 `pnpm-lock.yaml`。CI 只安装一个 Go 版本和一个固定的 pnpm 版本，然后调用根目录 Make 目标；不重复构建逻辑，也不增加版本矩阵。

**最小测试覆盖行为边界**

一个 Go HTTP 测试覆盖健康接口及响应契约。一个小型前端组件测试覆盖健康请求成功与失败。除现有 Vue/Vitest 生态所需内容外，不增加大型 fixture 或 mock 框架。

**项目级 Pi Extension 执行既定安全策略**

`.pi/extensions/safety-gate.ts` 使用 Pi 的 `tool_call` 拦截 API。它阻止 `write` 和 `edit` 直接修改环境文件、凭据路径、私钥或已提交的生成 API 声明；同时拦截递归删除、权限提升、破坏性 Git、强制推送、生产 PVE 访问、破坏性迁移和部署等危险 Bash 操作。

项目策略规定必须取得人工确认的操作使用 `ctx.ui.confirm`；拒绝、超时或无法显示确认界面时阻止工具调用。项目策略完全禁止的操作始终阻止。路径相对于 `ctx.cwd` 解析，不只依赖子串匹配。分类逻辑导出为小型纯函数，在不执行危险命令的情况下测试。Extension 只使用 Node 内置模块和 Pi Extension API。

曾考虑只依赖提示词。现有项目文档明确要求硬拦截层，因为提示词不能强制执行安全边界。

**OpenSpec 将英文规范正文与中文翻译分离**

每个新建或更新的 proposal、design、specification 和 task 产物先放置完整的英文规范内容，再在 `## 中文翻译（非规范性）` 下附上完整中文翻译。只有英文用于 OpenSpec 校验、实现和验收。规格翻译避免使用 OpenSpec 操作、需求、场景以及英文规范关键字语法；任务翻译不使用复选框语法。仓库级 OpenSpec 规则和 AI 开发文档保存这一约定，供后续变更使用。

曾考虑在两种语言中重复完整 OpenSpec 语法。这会使翻译后的需求和任务被解析为额外开发输入，并形成两个相互竞争的事实来源。

### 风险与权衡

- Gin 和 Ant Design Vue 增加依赖面 → 在 Go 和 pnpm 锁文件中固定依赖，并在 CI 中运行最小仓库检查。
- 当前就绪检查没有外部依赖，难以与存活检查形成差异 → 对当前进程如实响应，只在引入必需依赖后扩展。
- 已提交的生成类型可能漂移 → 在 `make check` 和 CI 中先生成，再检查工作树差异。
- 首个 CI 不覆盖生产部署或多个工具链版本 → 保持基线快速；只有出现兼容性或交付要求时才增加矩阵或部署。
- 命令匹配无法解析所有 Shell 构造 → 覆盖公共危险形式、解析受保护路径、测试拒绝路径、无 UI 时失败关闭，并确保生产凭据始终不提供给 Agent。
- 过宽的安全门可能阻止合法生成 → 只保护生成文件不被直接 edit/write，同时允许经过审查的 `make generate` 命令。
- 英文和中文内容可能产生偏差 → 只把英文视为规范来源，并要求在同一产物中提供完整的非规范翻译。
- 修改文档中的框架选择会影响后续实现指导 → 在同一变更中同步 README 和架构文档。
