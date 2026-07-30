## 1. GitHub App Bootstrap

- [x] 1.1 Add the reviewed App manifest and complete Owner registration confirmation
- [x] 1.2 Convert the manifest code, save the private key with mode `0600`, and record the App ID without logging secrets
- [x] 1.3 Install the App only on `cuihe500/CloudPilot-PVE`, record the installation ID, and verify exact permissions

## 2. PR Bot CLI

- [x] 2.1 Implement dependency-free App JWT and short-lived installation token generation using `openssl`, `jq`, and `gh`
- [x] 2.2 Implement repository, source branch, target branch, existing PR, identity, and required-body preflight checks
- [x] 2.3 Implement idempotent Draft creation, Owner reviewer request and read-back confirmation, and Ready transition
- [x] 2.4 Add fail-closed tests with a fake `gh` command covering invalid input, duplicate/conflicting PRs, reviewer failure, and successful readiness
- [x] 2.5 Document installation, invocation, credential rotation, prohibited operations, and recovery from a Draft failure

## 3. Repository Enforcement

- [ ] 3.1 Ensure CODEOWNERS and PR workflow require `@cuihe500` review
- [x] 3.2 Configure `main` for one CODEOWNER approval, stale approval dismissal, resolved conversations, admin enforcement, linear history, and no force push/deletion
- [x] 3.3 Create a real Draft PR with the App and verify that `@cuihe500` is requested before it becomes ready
- [ ] 3.4 Remove the Owner `gh` credential from the AI environment after all App acceptance checks pass

## 4. Verification and Delivery

- [ ] 4.1 Validate OpenSpec, shell syntax/tests, Markdown links, secret absence, App permissions, and branch protection
- [ ] 4.2 Run a read-only diff review and resolve all findings
- [ ] 4.3 Commit and push the implementation branch, create the PR with the App using `Closes #3`, and move the Project item to `In Review`
