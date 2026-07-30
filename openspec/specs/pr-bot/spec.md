# pr-bot Specification

## Purpose

Define the dedicated GitHub App identity, least-privilege credentials, fail-closed PR lifecycle, Owner review boundary, and repository protection used for AI-authored changes.

## Requirements

### Requirement: Repository-scoped App identity
The PR bot SHALL be a private GitHub App named `CloudPilot PVE PR Bot`, owned by `@cuihe500`, and installed only on `cuihe500/CloudPilot-PVE`.

#### Scenario: Owner installs the App
- **WHEN** the Owner completes GitHub App registration and installation
- **THEN** the installation includes only `cuihe500/CloudPilot-PVE`
- **THEN** webhooks, OAuth authorization, and Device Flow are disabled

### Requirement: Least-privilege permissions
The App SHALL have only Metadata read, Contents read, and Pull requests write repository permissions.

#### Scenario: Permission configuration is verified
- **WHEN** setup reads the installed App permissions
- **THEN** the three approved permissions match their required access levels
- **THEN** no code-write, administration, Actions, secrets, deployments, Issues, or Releases permission is granted

### Requirement: External credential storage
The bot SHALL keep its private key and installation configuration outside the repository and SHALL use only short-lived installation tokens for API calls.

#### Scenario: Credential files are valid
- **WHEN** the CLI loads bot credentials
- **THEN** it reads them from `~/.config/cloudpilot-pve-pr-bot/`
- **THEN** `private-key.pem` has mode `0600`
- **THEN** repository owner, name, App ID, installation ID, and App slug match the expected values

#### Scenario: Installation token is requested
- **WHEN** the CLI needs to call GitHub
- **THEN** it signs a short-lived App JWT and exchanges it for a short-lived installation token
- **THEN** the token is provided through the command process environment only
- **THEN** neither token nor private key is printed or stored by `gh auth login`

### Requirement: PR creation preflight
The bot SHALL create PRs only from existing remote development branches to `main` in the configured repository.

#### Scenario: Valid source branch
- **WHEN** the source branch exists on the configured remote, is not `main`, and has changes relative to `main`
- **THEN** the bot may continue to PR body validation

#### Scenario: Invalid source or target
- **WHEN** the source is missing, equals `main`, has no changes, or the requested target is not `main`
- **THEN** the command exits non-zero before creating a PR

### Requirement: Complete PR description
The bot SHALL reject a PR body that omits required review information.

#### Scenario: Body is complete
- **WHEN** the body contains Issue, OpenSpec, background, changes, verification, risks, contract or migration impact, UI evidence, and unfinished work sections
- **THEN** the bot may create or update the Draft PR

#### Scenario: Body is incomplete
- **WHEN** any required section is absent or empty without an explicit not-applicable explanation
- **THEN** the command exits non-zero and does not mark a PR ready

### Requirement: Draft-first Owner review
The bot SHALL keep a new PR in Draft until `@cuihe500` is confirmed as a requested reviewer.

#### Scenario: Reviewer request succeeds
- **WHEN** a Draft PR has a complete body and GitHub confirms `@cuihe500` in requested reviewers
- **THEN** the bot marks the PR ready for review

#### Scenario: Reviewer request fails
- **WHEN** GitHub rejects the reviewer request or the subsequent read does not contain `@cuihe500`
- **THEN** the PR remains Draft
- **THEN** the command exits non-zero without closing the PR or deleting the branch

### Requirement: Idempotent PR orchestration
The bot SHALL avoid duplicate PRs and SHALL modify only an open PR created by its own App identity for the same head and base.

#### Scenario: Matching bot Draft exists
- **WHEN** the create command finds a matching open Draft created by the configured App
- **THEN** it resumes safe body validation and reviewer confirmation on that PR
- **THEN** it does not create another PR

#### Scenario: Conflicting PR exists
- **WHEN** an open PR for the same head and base was created by another identity
- **THEN** the command exits non-zero without modifying that PR

### Requirement: Prohibited operations
The bot SHALL NOT push or modify code, merge or close PRs, submit reviews, delete branches, modify repository settings, manage Actions or secrets, deploy software, or access PVE.

#### Scenario: CLI command surface is inspected
- **WHEN** the checked-in bot CLI is reviewed or tested
- **THEN** it exposes no command or API route for a prohibited operation

### Requirement: Protected main branch
The repository SHALL require Owner approval before a PR can merge to `main`.

#### Scenario: Branch protection is configured
- **WHEN** protection for `main` is read
- **THEN** at least one approving review and CODEOWNER review are required
- **THEN** stale approvals are dismissed and review conversations must be resolved
- **THEN** administrators are included, linear history is required, and force pushes and deletion are disabled

#### Scenario: Last-push approval remains deferred
- **WHEN** the Owner-associated Git transport may still push development branches
- **THEN** approval of the most recent push is not required
- **THEN** the limitation is documented until a separate code-push identity exists

### Requirement: Owner credential isolation
The AI environment SHALL not retain the Owner's `gh` credential after the App has passed its acceptance checks.

#### Scenario: Bootstrap completes
- **WHEN** the bot has created a Draft PR, requested `@cuihe500`, and verified its permissions
- **THEN** the Owner `gh` login is removed from the AI environment
- **THEN** subsequent bot operations authenticate only with short-lived App installation tokens
