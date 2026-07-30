#!/usr/bin/env bash
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly BOT="$ROOT/scripts/pr-bot.sh"
readonly TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export CLOUDPILOT_PR_BOT_CONFIG_DIR="$TMP/config"
export FAKE_GH_DIR="$TMP/fake"
export PR_BOT_GH="$TMP/fake-gh"
mkdir -p "$CLOUDPILOT_PR_BOT_CONFIG_DIR" "$FAKE_GH_DIR"
chmod 700 "$CLOUDPILOT_PR_BOT_CONFIG_DIR"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$CLOUDPILOT_PR_BOT_CONFIG_DIR/private-key.pem" 2>/dev/null
chmod 600 "$CLOUDPILOT_PR_BOT_CONFIG_DIR/private-key.pem"
cat >"$CLOUDPILOT_PR_BOT_CONFIG_DIR/config.json" <<'EOF'
{"app_id":1,"installation_id":99,"app_slug":"cloudpilot-pve-pr-bot","owner":"cuihe500","repo":"CloudPilot-PVE"}
EOF
chmod 600 "$CLOUDPILOT_PR_BOT_CONFIG_DIR/config.json"

cat >"$PR_BOT_GH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%q ' "$@" >>"$FAKE_GH_DIR/log"
printf '\n' >>"$FAKE_GH_DIR/log"
args=" $* "
mode="$(cat "$FAKE_GH_DIR/mode" 2>/dev/null || printf success)"
case "$args" in
  *" /app/installations/99/access_tokens "*) printf '{"token":"fake-installation-token"}\n' ;;
  *" /app/installations/99 "*)
    printf '{"app_slug":"cloudpilot-pve-pr-bot","account":{"login":"cuihe500"},"repository_selection":"selected","permissions":{"metadata":"read","contents":"read","pull_requests":"write"}}\n'
    ;;
  *" /installation/repositories "*) printf '{"total_count":1,"repositories":[{"full_name":"cuihe500/CloudPilot-PVE"}]}\n' ;;
  *" /repos/cuihe500/CloudPilot-PVE/branches/"*) printf '{"name":"feature/test"}\n' ;;
  *" /repos/cuihe500/CloudPilot-PVE/compare/"*) printf '{"ahead_by":1}\n' ;;
  *" --method GET /repos/cuihe500/CloudPilot-PVE/pulls "*)
    case "$mode" in
      existing) printf '[{"number":7,"node_id":"PR_existing","draft":true,"user":{"login":"cloudpilot-pve-pr-bot[bot]"}}]\n' ;;
      conflict) printf '[{"number":8,"node_id":"PR_conflict","draft":true,"user":{"login":"someone-else"}}]\n' ;;
      *) printf '[]\n' ;;
    esac
    ;;
  *" --method POST /repos/cuihe500/CloudPilot-PVE/pulls "*)
    cat >/dev/null
    touch "$FAKE_GH_DIR/created"
    printf '{"number":9,"node_id":"PR_new","draft":true,"user":{"login":"cloudpilot-pve-pr-bot[bot]"}}\n'
    ;;
  *" --method PATCH /repos/cuihe500/CloudPilot-PVE/pulls/"*) cat >/dev/null; printf '{}\n' ;;
  *" --method POST /repos/cuihe500/CloudPilot-PVE/pulls/"*"/requested_reviewers "*)
    cat >/dev/null
    [[ "$mode" != reviewer-error ]] || exit 1
    printf '{}\n'
    ;;
  *"/requested_reviewers "*)
    if [[ "$mode" == reviewer-missing ]]; then
      printf '{"users":[]}\n'
    else
      printf '{"users":[{"login":"cuihe500"}]}\n'
    fi
    ;;
  *" graphql "*)
    touch "$FAKE_GH_DIR/ready"
    if [[ "$mode" == ready-still-draft ]]; then
      printf '{"data":{"markPullRequestReadyForReview":{"pullRequest":{"number":9,"isDraft":true}}}}\n'
    else
      printf '{"data":{"markPullRequestReadyForReview":{"pullRequest":{"number":9,"isDraft":false}}}}\n'
    fi
    ;;
  *) printf 'unexpected fake gh call: %s\n' "$args" >&2; exit 97 ;;
esac
EOF
chmod +x "$PR_BOT_GH"

cat >"$TMP/body.md" <<'EOF'
## 关联
- Issue：Closes #3
- OpenSpec：`openspec/changes/setup-pr-bot/`
## 背景与目标
Create the dedicated PR bot.
## 修改内容
- Bot CLI
## 验证
- Tests passed
## 安全与风险
- Least privilege
## 契约、数据与配置
No runtime contract changes.
## 界面证据
No UI changes.
## 未完成项
None.
EOF

run_create() {
  "$BOT" create --head feature/test --title 'chore: test bot' --body-file "$1"
}

expect_failure() {
  if "$@" >"$TMP/stdout" 2>"$TMP/stderr"; then
    printf 'expected command to fail: %q ' "$@" >&2
    exit 1
  fi
}

# Unsafe credential permissions fail before any GitHub call.
chmod 644 "$CLOUDPILOT_PR_BOT_CONFIG_DIR/private-key.pem"
: >"$FAKE_GH_DIR/log"
expect_failure "$BOT" verify
[[ ! -s "$FAKE_GH_DIR/log" ]]
chmod 600 "$CLOUDPILOT_PR_BOT_CONFIG_DIR/private-key.pem"

# Invalid branches and incomplete bodies fail before GitHub mutation.
expect_failure "$BOT" create --head main --title bad --body-file "$TMP/body.md"
cp "$TMP/body.md" "$TMP/incomplete.md"
sed -i '/## 未完成项/,$d' "$TMP/incomplete.md"
: >"$FAKE_GH_DIR/log"
expect_failure run_create "$TMP/incomplete.md"
[[ ! -s "$FAKE_GH_DIR/log" ]]
cp "$TMP/body.md" "$TMP/placeholder.md"
printf '\n<!-- unresolved -->\n' >>"$TMP/placeholder.md"
expect_failure run_create "$TMP/placeholder.md"
[[ ! -s "$FAKE_GH_DIR/log" ]]

# A conflicting PR is never modified.
printf conflict >"$FAKE_GH_DIR/mode"
rm -f "$FAKE_GH_DIR/created" "$FAKE_GH_DIR/ready"
expect_failure run_create "$TMP/body.md"
[[ ! -e "$FAKE_GH_DIR/created" && ! -e "$FAKE_GH_DIR/ready" ]]

# Missing reviewer confirmation leaves the newly created PR in Draft.
printf reviewer-missing >"$FAKE_GH_DIR/mode"
rm -f "$FAKE_GH_DIR/created" "$FAKE_GH_DIR/ready"
expect_failure run_create "$TMP/body.md"
[[ -e "$FAKE_GH_DIR/created" && ! -e "$FAKE_GH_DIR/ready" ]]

# A mutation that does not confirm readiness fails closed.
printf ready-still-draft >"$FAKE_GH_DIR/mode"
rm -f "$FAKE_GH_DIR/created" "$FAKE_GH_DIR/ready"
expect_failure run_create "$TMP/body.md"
[[ -e "$FAKE_GH_DIR/created" && -e "$FAKE_GH_DIR/ready" ]]

# Success creates one Draft, requests the Owner, and then marks it ready.
printf success >"$FAKE_GH_DIR/mode"
rm -f "$FAKE_GH_DIR/created" "$FAKE_GH_DIR/ready"
url="$(run_create "$TMP/body.md")"
[[ "$url" == "https://github.com/cuihe500/CloudPilot-PVE/pull/9" ]]
[[ -e "$FAKE_GH_DIR/created" && -e "$FAKE_GH_DIR/ready" ]]

# Re-running against the bot's Draft updates it rather than creating a duplicate.
printf existing >"$FAKE_GH_DIR/mode"
rm -f "$FAKE_GH_DIR/created" "$FAKE_GH_DIR/ready"
url="$(run_create "$TMP/body.md")"
[[ "$url" == "https://github.com/cuihe500/CloudPilot-PVE/pull/7" ]]
[[ ! -e "$FAKE_GH_DIR/created" && -e "$FAKE_GH_DIR/ready" ]]

printf 'pr-bot tests passed\n'
