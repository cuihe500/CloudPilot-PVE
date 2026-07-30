#!/usr/bin/env bash
set -euo pipefail

readonly EXPECTED_OWNER="cuihe500"
readonly EXPECTED_REPO="CloudPilot-PVE"
readonly EXPECTED_SLUG="cloudpilot-pve-pr-bot"
readonly EXPECTED_REVIEWER="cuihe500"
readonly CONFIG_DIR="${CLOUDPILOT_PR_BOT_CONFIG_DIR:-$HOME/.config/cloudpilot-pve-pr-bot}"
readonly CONFIG_FILE="$CONFIG_DIR/config.json"
readonly KEY_FILE="$CONFIG_DIR/private-key.pem"
readonly STATE_FILE="$CONFIG_DIR/manifest-state"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MANIFEST_FILE="$SCRIPT_DIR/pr-bot-manifest.json"
readonly GH="${PR_BOT_GH:-gh}"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

base64url() {
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

urlencode() {
  jq -rn --arg value "$1" '$value | @uri'
}

load_config() {
  [[ -d "$CONFIG_DIR" && "$(file_mode "$CONFIG_DIR")" == "700" ]] || fail "$CONFIG_DIR must have mode 700"
  [[ -f "$CONFIG_FILE" && ! -L "$CONFIG_FILE" ]] || fail "missing or unsafe config: $CONFIG_FILE"
  [[ -f "$KEY_FILE" && ! -L "$KEY_FILE" ]] || fail "missing or unsafe private key: $KEY_FILE"
  [[ "$(file_mode "$CONFIG_FILE")" == "600" ]] || fail "$CONFIG_FILE must have mode 600"
  [[ "$(file_mode "$KEY_FILE")" == "600" ]] || fail "$KEY_FILE must have mode 600"

  APP_ID="$(jq -er '.app_id | numbers' "$CONFIG_FILE")"
  INSTALLATION_ID="$(jq -er '.installation_id | numbers' "$CONFIG_FILE")"
  APP_SLUG="$(jq -er '.app_slug | strings' "$CONFIG_FILE")"
  OWNER="$(jq -er '.owner | strings' "$CONFIG_FILE")"
  REPO="$(jq -er '.repo | strings' "$CONFIG_FILE")"

  [[ "$APP_SLUG" == "$EXPECTED_SLUG" ]] || fail "unexpected App slug: $APP_SLUG"
  [[ "$OWNER" == "$EXPECTED_OWNER" ]] || fail "unexpected repository owner: $OWNER"
  [[ "$REPO" == "$EXPECTED_REPO" ]] || fail "unexpected repository name: $REPO"
}

app_jwt() {
  local now header payload unsigned
  now="$(date +%s)"
  header="$(printf '%s' '{"alg":"RS256","typ":"JWT"}' | base64url)"
  payload="$(printf '{"iat":%d,"exp":%d,"iss":%s}' "$((now - 60))" "$((now + 540))" "$APP_ID" | base64url)"
  unsigned="$header.$payload"
  printf '%s.%s' "$unsigned" "$(printf '%s' "$unsigned" | openssl dgst -sha256 -sign "$KEY_FILE" -binary | base64url)"
}

app_api() {
  local jwt
  jwt="$(app_jwt)"
  GH_TOKEN="$jwt" "$GH" api -H "Authorization: Bearer $jwt" "$@"
}

installation_token() {
  local jwt
  jwt="$(app_jwt)"
  GH_TOKEN="$jwt" "$GH" api -H "Authorization: Bearer $jwt" --method POST "/app/installations/$INSTALLATION_ID/access_tokens" --jq '.token'
}

installation_api() {
  local token
  token="$(installation_token)"
  GH_TOKEN="$token" "$GH" api "$@"
}

verify_installation() {
  local installation repositories extra_permissions
  installation="$(app_api "/app/installations/$INSTALLATION_ID")"

  [[ "$(jq -r '.app_slug' <<<"$installation")" == "$EXPECTED_SLUG" ]] || fail "installation App slug mismatch"
  [[ "$(jq -r '.account.login' <<<"$installation")" == "$EXPECTED_OWNER" ]] || fail "installation owner mismatch"
  [[ "$(jq -r '.repository_selection' <<<"$installation")" == "selected" ]] || fail "App must use selected repositories"
  [[ "$(jq -r '.permissions.metadata' <<<"$installation")" == "read" ]] || fail "metadata permission must be read"
  [[ "$(jq -r '.permissions.contents' <<<"$installation")" == "read" ]] || fail "contents permission must be read"
  [[ "$(jq -r '.permissions.pull_requests' <<<"$installation")" == "write" ]] || fail "pull_requests permission must be write"
  extra_permissions="$(jq -r '.permissions | to_entries[] | select(.key != "metadata" and .key != "contents" and .key != "pull_requests") | "\(.key)=\(.value)"' <<<"$installation")"
  [[ -z "$extra_permissions" ]] || fail "unexpected App permissions: $extra_permissions"

  repositories="$(installation_api /installation/repositories)"
  [[ "$(jq -r '.total_count' <<<"$repositories")" == "1" ]] || fail "App must be installed on exactly one repository"
  [[ "$(jq -r '.repositories[0].full_name' <<<"$repositories")" == "$EXPECTED_OWNER/$EXPECTED_REPO" ]] || fail "unexpected installed repository"
}

registration_page() {
  local output="${1:-/tmp/cloudpilot-pve-pr-bot-register.html}" state manifest escaped
  [[ -f "$MANIFEST_FILE" ]] || fail "missing manifest: $MANIFEST_FILE"
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR"
  state="$(openssl rand -hex 32)"
  printf '%s' "$state" >"$STATE_FILE"
  chmod 600 "$STATE_FILE"
  manifest="$(jq -c . "$MANIFEST_FILE")"
  escaped="$(jq -rn --arg value "$manifest" '$value | @html')"
  cat >"$output" <<EOF
<!doctype html>
<meta charset="utf-8">
<title>Register CloudPilot PVE PR Bot</title>
<p>This registers a private, repository-scoped GitHub App with read-only contents and pull-request write access.</p>
<form action="https://github.com/settings/apps/new?state=$state" method="post">
  <input type="hidden" name="manifest" value="$escaped">
  <button type="submit">Register CloudPilot PVE PR Bot</button>
</form>
EOF
  chmod 600 "$output"
  printf '%s\n' "$output"
}

convert_manifest() {
  local code="${1:-}" state="${2:-}" response
  [[ -n "$code" && -n "$state" ]] || fail "usage: $0 convert <code> <state>"
  [[ -f "$STATE_FILE" ]] || fail "registration state is missing or expired"
  [[ "$(<"$STATE_FILE")" == "$state" ]] || fail "registration state mismatch"
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR"
  umask 077
  response="$(mktemp "$CONFIG_DIR/manifest-response.XXXXXX")"
  trap 'rm -f "$response"' RETURN
  "$GH" api --method POST "/app-manifests/$code/conversions" >"$response"
  [[ "$(jq -er '.slug' "$response")" == "$EXPECTED_SLUG" ]] || fail "GitHub created an unexpected App slug"
  jq -er '.pem' "$response" >"$KEY_FILE"
  chmod 600 "$KEY_FILE"
  jq -n \
    --argjson app_id "$(jq -er '.id' "$response")" \
    --arg app_slug "$EXPECTED_SLUG" \
    --arg owner "$EXPECTED_OWNER" \
    --arg repo "$EXPECTED_REPO" \
    '{app_id: $app_id, installation_id: null, app_slug: $app_slug, owner: $owner, repo: $repo}' >"$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
  rm -f "$STATE_FILE" "$response"
  trap - RETURN
  printf 'App registered. Install it at:\nhttps://github.com/apps/%s/installations/new\n' "$EXPECTED_SLUG"
}

finalize_installation() {
  local app_id slug owner repo installation installation_id
  [[ -f "$CONFIG_FILE" && -f "$KEY_FILE" ]] || fail "convert the manifest before finalizing installation"
  APP_ID="$(jq -er '.app_id | numbers' "$CONFIG_FILE")"
  slug="$(jq -er '.app_slug' "$CONFIG_FILE")"
  owner="$(jq -er '.owner' "$CONFIG_FILE")"
  repo="$(jq -er '.repo' "$CONFIG_FILE")"
  [[ "$slug" == "$EXPECTED_SLUG" && "$owner" == "$EXPECTED_OWNER" && "$repo" == "$EXPECTED_REPO" ]] || fail "bootstrap config identity mismatch"
  installation="$(app_api /app/installations)"
  installation_id="$(jq -er --arg owner "$EXPECTED_OWNER" '[.[] | select(.account.login == $owner)] | if length == 1 then .[0].id else error("expected exactly one owner installation") end' <<<"$installation")"
  jq --argjson installation_id "$installation_id" '.installation_id = $installation_id' "$CONFIG_FILE" >"$CONFIG_FILE.tmp"
  mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
  load_config
  verify_installation
  printf 'Installation verified for %s/%s (installation %s).\n' "$OWNER" "$REPO" "$INSTALLATION_ID"
}

validate_body() {
  local body_file="$1" heading
  [[ -f "$body_file" ]] || fail "PR body file does not exist: $body_file"
  grep -Eq 'Issue.*(#[0-9]+|N/A)' "$body_file" || fail "PR body must identify an Issue or explain N/A"
  grep -Eq 'OpenSpec.*(`?openspec/changes/|N/A)' "$body_file" || fail "PR body must identify an OpenSpec change or explain N/A"
  while IFS= read -r heading; do
    grep -Fqx "$heading" "$body_file" || fail "PR body is missing section: $heading"
    awk -v heading="$heading" '
      $0 == heading { inside=1; next }
      inside && /^## / { exit }
      inside {
        line=$0
        gsub(/<!--[[:space:][:print:]]*-->/, "", line)
        gsub(/[[:space:]]/, "", line)
        if (length(line) > 0) found=1
      }
      END { exit(found ? 0 : 1) }
    ' "$body_file" || fail "PR body section is empty: $heading"
  done <<'EOF'
## 关联
## 背景与目标
## 修改内容
## 验证
## 安全与风险
## 契约、数据与配置
## 界面证据
## 未完成项
EOF
}

create_pr() {
  local head="" title="" body_file="" head_encoded compare pulls count number node_id actor draft token payload reviewers
  while (($#)); do
    case "$1" in
      --head) head="${2:-}"; shift 2 ;;
      --title) title="${2:-}"; shift 2 ;;
      --body-file) body_file="${2:-}"; shift 2 ;;
      *) fail "unknown create argument: $1" ;;
    esac
  done
  [[ -n "$head" && -n "$title" && -n "$body_file" ]] || fail "usage: $0 create --head <branch> --title <title> --body-file <path>"
  [[ "$head" != "main" ]] || fail "source branch cannot be main"
  [[ "$head" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] || fail "invalid source branch"
  validate_body "$body_file"
  load_config
  verify_installation

  token="$(installation_token)"
  head_encoded="$(urlencode "$head")"
  GH_TOKEN="$token" "$GH" api "/repos/$OWNER/$REPO/branches/$head_encoded" >/dev/null || fail "remote source branch does not exist: $head"
  compare="$(GH_TOKEN="$token" "$GH" api "/repos/$OWNER/$REPO/compare/main...$head_encoded")"
  (( "$(jq -r '.ahead_by' <<<"$compare")" > 0 )) || fail "source branch has no changes relative to main"

  pulls="$(GH_TOKEN="$token" "$GH" api --method GET "/repos/$OWNER/$REPO/pulls" -f state=open -f base=main -f "head=$OWNER:$head")"
  count="$(jq 'length' <<<"$pulls")"
  (( count <= 1 )) || fail "multiple open PRs exist for $head"
  if (( count == 1 )); then
    actor="$(jq -r '.[0].user.login' <<<"$pulls")"
    [[ "$actor" == "$APP_SLUG[bot]" ]] || fail "an open PR for $head is owned by $actor, not the configured bot"
    number="$(jq -r '.[0].number' <<<"$pulls")"
    node_id="$(jq -r '.[0].node_id' <<<"$pulls")"
    draft="$(jq -r '.[0].draft' <<<"$pulls")"
    payload="$(jq -n --arg title "$title" --rawfile body "$body_file" '{title: $title, body: $body}')"
    GH_TOKEN="$token" "$GH" api --method PATCH "/repos/$OWNER/$REPO/pulls/$number" --input - <<<"$payload" >/dev/null
  else
    payload="$(jq -n --arg title "$title" --arg head "$head" --rawfile body "$body_file" '{title: $title, head: $head, base: "main", body: $body, draft: true}')"
    pulls="$(GH_TOKEN="$token" "$GH" api --method POST "/repos/$OWNER/$REPO/pulls" --input - <<<"$payload")"
    number="$(jq -r '.number' <<<"$pulls")"
    node_id="$(jq -r '.node_id' <<<"$pulls")"
    draft=true
  fi

  payload="$(jq -n --arg reviewer "$EXPECTED_REVIEWER" '{reviewers: [$reviewer]}')"
  GH_TOKEN="$token" "$GH" api --method POST "/repos/$OWNER/$REPO/pulls/$number/requested_reviewers" --input - <<<"$payload" >/dev/null
  reviewers="$(GH_TOKEN="$token" "$GH" api "/repos/$OWNER/$REPO/pulls/$number/requested_reviewers")"
  jq -e --arg reviewer "$EXPECTED_REVIEWER" '.users | any(.login == $reviewer)' <<<"$reviewers" >/dev/null || fail "Owner reviewer was not confirmed; PR #$number remains Draft"

  if [[ "$draft" == "true" ]]; then
    GH_TOKEN="$token" "$GH" api graphql \
      -f query='mutation($id:ID!){markPullRequestReadyForReview(input:{pullRequestId:$id}){pullRequest{number isDraft}}}' \
      -F id="$node_id" --jq '.data.markPullRequestReadyForReview.pullRequest' >/dev/null
  fi
  printf 'https://github.com/%s/%s/pull/%s\n' "$OWNER" "$REPO" "$number"
}

pr_status() {
  local number="${1:-}" result token
  [[ "$number" =~ ^[0-9]+$ ]] || fail "usage: $0 status <pr-number>"
  load_config
  token="$(installation_token)"
  result="$(GH_TOKEN="$token" "$GH" api "/repos/$OWNER/$REPO/pulls/$number")"
  [[ "$(jq -r '.user.login' <<<"$result")" == "$APP_SLUG[bot]" ]] || fail "PR #$number was not created by the configured bot"
  jq '{number, state, draft, title, html_url, author: .user.login, requested_reviewers: [.requested_reviewers[].login]}' <<<"$result"
}

usage() {
  cat <<EOF
Usage:
  $0 registration-page [output.html]
  $0 convert <code> <state>
  $0 finalize
  $0 verify
  $0 create --head <branch> --title <title> --body-file <path>
  $0 status <pr-number>
EOF
}

main() {
  need gh
  need jq
  need openssl
  need stat
  case "${1:-}" in
    registration-page) shift; registration_page "$@" ;;
    convert) shift; convert_manifest "$@" ;;
    finalize) shift; finalize_installation "$@" ;;
    verify) load_config; verify_installation; printf 'App installation and permissions verified.\n' ;;
    create) shift; create_pr "$@" ;;
    status) shift; pr_status "$@" ;;
    *) usage; exit 2 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
