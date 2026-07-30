## 1. Tooling and Safety Gate

- [x] 1.1 Install the official stable Go toolchain and global pnpm, then pin the selected Go and pnpm versions in repository manifests and CI.
- [x] 1.2 Implement `.pi/extensions/safety-gate.ts` with resolved protected-path checks, prohibited-command blocking, and fail-closed interactive confirmation for confirmation-gated operations.
- [x] 1.3 Add and run focused safety-gate tests for protected paths, prohibited commands, confirmation-gated commands, non-interactive denial, and ordinary allowed operations.

## 2. API Contract and Backend

- [x] 2.1 Add `api/openapi.yaml` defining the health/readiness operations, shared response schema, and stable content types/statuses.
- [x] 2.2 Initialize the Go module and implement `internal/httpapi` with a Gin engine serving `/api/healthz` and `/api/readyz`.
- [x] 2.3 Implement `cmd/cloudpilot` with slog startup/error logging, explicit HTTP server timeouts, signal handling, and graceful shutdown.
- [x] 2.4 Add HTTP tests proving both endpoints satisfy the OpenAPI response behavior and do not expose internal details.

## 3. Vue Frontend

- [x] 3.1 Create the pnpm-managed Vue 3, TypeScript, Vite, and Ant Design Vue application with a development `/api` proxy and pinned package manager.
- [x] 3.2 Configure `openapi-typescript` generation and `openapi-fetch` consumption without handwritten duplicate API DTOs.
- [x] 3.3 Implement the single health status view with loading, available, and non-sensitive connection-failure states.
- [x] 3.4 Add focused frontend tests for successful and failed health requests, plus TypeScript and ESLint configuration.

## 4. Unified Automation

- [x] 4.1 Add root `make generate`, `make test`, `make check`, and `make build` targets covering the safety gate, Go service, OpenAPI generation, and Vue application.
- [x] 4.2 Make `make check` fail when OpenAPI type regeneration changes the committed generated declaration.
- [x] 4.3 Add a minimal GitHub Actions pull-request workflow that installs the pinned Go and pnpm toolchains and runs `make check` plus `make build`.

## 5. Documentation and Verification

- [x] 5.1 Update README and `docs/architecture.md` to document Gin, Ant Design Vue, pnpm, the runnable foundation, and unchanged trust boundaries.
- [x] 5.2 Codify normative-English/non-normative-Chinese OpenSpec authoring in repository configuration and AI development documentation.
- [x] 5.3 Run `make generate`, `make test`, `make check`, and `make build`; record actual results and any environment limitations.
- [x] 5.4 Validate the OpenSpec change, review the complete diff for secrets and scope drift, and resolve all valid findings before delivery.

---

## 中文翻译（非规范性）

> 本节仅为英文任务清单的翻译，不参与任务解析或进度跟踪；任务状态只以英文复选框为准。

### 1. 工具链与安全门

1.1 安装官方稳定版 Go 工具链和全局 pnpm，并在仓库清单与 CI 中固定所选 Go 和 pnpm 版本。

1.2 实现 `.pi/extensions/safety-gate.ts`，包含解析后的受保护路径检查、禁止命令拦截，以及对需要确认操作的失败关闭式交互确认。

1.3 增加并运行聚焦的安全门测试，覆盖受保护路径、禁止命令、需要确认的命令、非交互拒绝和普通允许操作。

### 2. API 契约与后端

2.1 增加 `api/openapi.yaml`，定义健康/就绪操作、共享响应结构及稳定的内容类型和状态码。

2.2 初始化 Go Module，并在 `internal/httpapi` 中实现 Gin 引擎，提供 `/api/healthz` 和 `/api/readyz`。

2.3 实现 `cmd/cloudpilot`，包含 slog 启动/错误日志、明确的 HTTP 服务超时、信号处理和优雅关闭。

2.4 增加 HTTP 测试，证明两个接口符合 OpenAPI 响应行为且不暴露内部细节。

### 3. Vue 前端

3.1 创建由 pnpm 管理的 Vue 3、TypeScript、Vite 和 Ant Design Vue 应用，配置开发环境 `/api` 代理并固定包管理器。

3.2 配置 `openapi-typescript` 生成和 `openapi-fetch` 使用，不手写重复 API DTO。

3.3 实现单一健康状态页面，包含加载、可用和不含敏感信息的连接失败状态。

3.4 增加聚焦的前端测试，覆盖健康请求成功与失败，并增加 TypeScript 和 ESLint 配置。

### 4. 统一自动化

4.1 在根目录增加 `make generate`、`make test`、`make check` 和 `make build`，覆盖安全门、Go 服务、OpenAPI 生成和 Vue 应用。

4.2 当 OpenAPI 类型重新生成改变已提交声明时，使 `make check` 失败。

4.3 增加最小 GitHub Actions Pull Request 工作流，安装固定的 Go 和 pnpm 工具链，并运行 `make check` 与 `make build`。

### 5. 文档与验证

5.1 更新 README 和 `docs/architecture.md`，记录 Gin、Ant Design Vue、pnpm、可运行基础和未改变的信任边界。

5.2 在仓库配置和 AI 开发文档中固化“英文规范正文、中文非规范翻译”的 OpenSpec 编写规则。

5.3 运行 `make generate`、`make test`、`make check` 和 `make build`，记录实际结果及环境限制。

5.4 验证 OpenSpec 变更，检查完整 diff 中的秘密和范围漂移，并在交付前处理所有有效发现。
