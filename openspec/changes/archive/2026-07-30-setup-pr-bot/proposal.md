## Why

Issue #3 requires an independent PR author so project Owner `@cuihe500` can perform a real GitHub review. The current AI environment creates PRs as the Owner, and GitHub forbids requesting review from the PR author.

## What Changes

- Register the private GitHub App `CloudPilot PVE PR Bot` under `@cuihe500` and install it only on `cuihe500/CloudPilot-PVE`.
- Grant only Metadata read, Contents read, and Pull requests write permissions; disable webhooks, OAuth, and Device Flow.
- Add a versioned CLI that creates Draft PRs from existing remote branches, validates the PR body, requests `@cuihe500`, verifies that request, and only then marks the PR ready.
- Store the App private key and installation configuration outside the repository and use short-lived installation tokens.
- Require CODEOWNER approval on `main`, while preventing the bot from pushing code, merging, closing, reviewing, or deleting branches.
- Remove the Owner's `gh` credential from the AI environment after bootstrap.

## Capabilities

### New Capabilities

- `pr-bot`: Defines the identity, permissions, credential handling, fail-closed PR lifecycle, and repository protection required for the dedicated PR bot.

### Modified Capabilities

None.

## Impact

- GitHub: creates one private GitHub App, one repository installation, Owner review protection, and PR review requests.
- Repository: adds the bot CLI, operator documentation, CODEOWNERS/PR workflow updates, and tests that do not use production credentials.
- Local environment: stores App credentials under `~/.config/cloudpilot-pve-pr-bot/` with restrictive permissions.
- Runtime application, OpenAPI, database, and PVE: no impact.
