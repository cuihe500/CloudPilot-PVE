## Context

Issue #3 establishes a dedicated GitHub App as the PR author so `@cuihe500` can remain the human reviewer. The AI environment currently has the Owner's `gh` credential, while GitHub rejects self-review requests. The App is a local, explicitly invoked CLI identity; it has no server, webhook, OAuth flow, or responsibility for code generation.

The repository is simultaneously bootstrapping its OpenSpec and Project workflow. This change is developed in an isolated worktree so the staged work for Issue #2 is not modified.

## Goals / Non-Goals

**Goals:**

- Create a repository-scoped GitHub App with the minimum permissions needed to create and maintain PRs.
- Make incomplete PR creation fail closed by keeping the PR in Draft until the Owner reviewer is confirmed.
- Keep all long-lived secrets outside Git and use short-lived installation tokens.
- Enforce Owner approval through CODEOWNERS and branch protection.
- Leave an auditable, dependency-free CLI implementation in the repository.

**Non-Goals:**

- Pushing or editing code, deleting branches, merging or closing PRs, or submitting reviews.
- Running as a hosted service or responding to webhooks.
- Managing Issues, Releases, Actions, deployments, repository settings, or PVE.
- Creating a general-purpose GitHub automation framework.

## Decisions

### Use a private GitHub App rather than a machine user

The App identity is `CloudPilot PVE PR Bot` and is installed only on `cuihe500/CloudPilot-PVE`. Installation tokens expire quickly and repository permissions are explicit. A machine user would require a separately maintained account and long-lived PAT; `github-actions[bot]` would not be usable from local pi sessions.

Registration uses the official App Manifest flow. The Owner performs the required browser confirmations; manifest conversion, installation discovery, token generation, and verification use `gh api`.

### Grant only metadata read, contents read, and pull requests write

Contents is read-only because source branches already exist before the bot runs. Pull requests write is required to create Draft PRs, update their metadata, request reviewers, and mark them ready. No permission grants code writes, Actions, administration, deployments, or secrets access.

GitHub permission groups are broader than individual operations, so Pull requests write can expose operations the policy forbids, such as closing a PR. The checked-in CLI exposes only an allowlist of commands, and branch protection separately prevents unapproved merges.

### Store credentials outside the repository

`~/.config/cloudpilot-pve-pr-bot/private-key.pem` is mode `0600`. `config.json` contains only App ID, installation ID, owner, repository, and expected App slug. The CLI rejects unsafe file permissions or mismatched repository identity.

The CLI signs a short-lived App JWT with `openssl`, exchanges it for an installation token using `gh api`, and passes that token only through the child command's `GH_TOKEN`. It never calls `gh auth login` for the App or prints tokens.

### Use a Draft-first, fail-closed PR lifecycle

The create command verifies a non-main source branch exists on the expected remote, the base is exactly `main`, no conflicting open PR exists, and the body contains every required section. It then creates a Draft PR, requests `@cuihe500`, reads the requested reviewers back, and marks the PR ready only after confirmation.

If any post-creation step fails, the PR remains Draft and the command exits non-zero. The bot does not close the PR or delete the branch. Re-running the command discovers the bot-owned Draft PR and resumes the missing safe steps instead of creating duplicates.

### Separate AI and Owner credentials

The Owner credential is used only to register/install the App and configure protection. After the bot is verified, the Owner's `gh` authentication is removed from the AI environment. Human approval and merge happen from a separate Owner-controlled browser or terminal.

The existing Owner-associated Git transport may temporarily push development branches. Therefore branch protection does not enable “approval of the most recent push”; that control waits for a separate code-push identity.

### Enforce review at the branch boundary

`main` requires one approving review, CODEOWNER approval from `@cuihe500`, dismissal of stale approvals, resolved conversations, linear history, and protection for administrators. Force pushes and branch deletion are disabled. Required CI checks are added after CI exists.

## Risks / Trade-offs

- **Pull requests write is broader than the behavioral allowlist** → Keep the CLI command surface small, test API routes, and rely on branch protection for merge safety.
- **A local private key can be copied by the host user** → Store it outside Git with `0600`, avoid backups in project files, and document immediate key revocation.
- **Removing Owner `gh` auth can interrupt unrelated owner automation** → Perform removal only after App verification and report the exact credential store changed.
- **The Owner may be the last branch pusher** → Do not require last-push approval until a separate code identity exists.
- **Manifest registration needs browser interaction** → Limit interaction to the two explicit Owner confirmations and complete the one-hour conversion window immediately.

## Migration Plan

1. Create and schedule Issue #3, then approve this OpenSpec.
2. Register the private App through the manifest flow and save its private key securely.
3. Install it only on `cuihe500/CloudPilot-PVE` and record the installation ID.
4. Add and test the repository CLI without exposing credentials.
5. Use the App to create a Draft PR and confirm `@cuihe500` is requested.
6. Enable one CODEOWNER approval in branch protection.
7. Remove Owner `gh` authentication from the AI environment.

Rollback revokes the App private key, suspends or uninstalls the App, and reverts the repository CLI/policy change. Branch protection remains at least as strict as before; it is not weakened automatically.

## Open Questions

None. The Owner approved the identity, permissions, Draft-first lifecycle, credential location, and branch protection decisions during the grilling session for Issue #3.
