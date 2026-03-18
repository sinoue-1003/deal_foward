#!/bin/bash
# =============================================================================
# deal_foward — ローカル環境セットアップスクリプト
# =============================================================================
# 使い方: ./setup.sh
# =============================================================================

set -euo pipefail

# ---------- 色付き出力 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}\n"; }
prompt()  { echo -e "${YELLOW}$1${NC}"; }
link()    { echo -e "  ${CYAN}→ $1${NC}"; }

# ---------- ユーティリティ ----------
command_exists() { command -v "$1" &>/dev/null; }

generate_secret() {
  if command_exists openssl; then
    openssl rand -hex 32
  else
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
  fi
}

read_input() {
  local var_name="$1"
  local label="$2"
  local default_val="${3:-}"
  local is_secret="${4:-false}"

  if [ -n "$default_val" ]; then
    prompt "  ${label}"
    echo -e "  ${BLUE}(Enter でスキップ → デフォルト値を使用)${NC}"
  else
    prompt "  ${label}"
    echo -e "  ${BLUE}(Enter でスキップ)${NC}"
  fi

  if [ "$is_secret" = "true" ]; then
    read -rsp "  > " input_val
    echo
  else
    read -rp "  > " input_val
  fi

  if [ -z "$input_val" ] && [ -n "$default_val" ]; then
    input_val="$default_val"
  fi

  eval "$var_name='${input_val}'"
}

# ---------- バナー ----------
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       deal_foward  ローカル環境セットアップ              ║"
echo "║       営業AIエージェント × コミュニケーションPF          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# =============================================================================
# 1. 起動モード選択
# =============================================================================
section "起動モード選択"
echo "  1) Docker Compose  ← 推奨 (要 Docker)"
echo "  2) ローカル直接起動 (要 Ruby 3.3 / Node.js)"
echo
read -rp "  モードを選択してください [1/2]: " MODE_CHOICE
MODE_CHOICE="${MODE_CHOICE:-1}"

if [ "$MODE_CHOICE" = "1" ]; then
  USE_DOCKER=true
  info "Docker Compose モードで設定します"
else
  USE_DOCKER=false
  info "ローカル直接起動モードで設定します"
fi

# =============================================================================
# 2. 前提ツール確認
# =============================================================================
section "前提ツール確認"

MISSING_TOOLS=()

if [ "$USE_DOCKER" = "true" ]; then
  if command_exists docker; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
    success "Docker: ${DOCKER_VERSION}"
    if docker compose version &>/dev/null 2>&1; then
      COMPOSE_CMD="docker compose"
      success "Docker Compose: $(docker compose version --short)"
    elif command_exists docker-compose; then
      COMPOSE_CMD="docker-compose"
      success "docker-compose: $(docker-compose --version | awk '{print $3}' | tr -d ',')"
    else
      MISSING_TOOLS+=("docker-compose")
    fi
  else
    MISSING_TOOLS+=("docker")
  fi
else
  if command_exists ruby; then
    RUBY_VERSION=$(ruby --version | awk '{print $2}')
    success "Ruby: ${RUBY_VERSION}"
    if command_exists bundle; then
      success "Bundler: $(bundle --version | awk '{print $3}')"
    else
      MISSING_TOOLS+=("bundler (gem install bundler)")
    fi
  else
    MISSING_TOOLS+=("ruby (rbenv or RVM 推奨)")
  fi
  if command_exists node; then
    success "Node.js: $(node --version)"
  else
    MISSING_TOOLS+=("node.js")
  fi
  if command_exists npm; then
    success "npm: $(npm --version)"
  else
    MISSING_TOOLS+=("npm")
  fi
fi

if command_exists psql; then
  success "psql: $(psql --version | awk '{print $3}')"
else
  warn "psql が見つかりません (DB接続確認はスキップします)"
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
  echo
  error "以下のツールをインストールしてください:"
  for tool in "${MISSING_TOOLS[@]}"; do
    echo "    - $tool"
  done
  exit 1
fi

success "全ての前提ツールが揃っています"

# =============================================================================
# 3. .env ファイルの既存確認
# =============================================================================
section ".env ファイル設定"

ROOT_ENV=".env"
BACKEND_ENV="backend/.env"

check_overwrite() {
  local filepath="$1"
  local varname="$2"
  if [ -f "$filepath" ]; then
    warn "${filepath} が既に存在します"
    read -rp "  上書きしますか? [y/N]: " ow
    if [[ "$ow" =~ ^[Yy]$ ]]; then eval "$varname=false"; else eval "$varname=true"; fi
  else
    eval "$varname=false"
  fi
}

check_overwrite "$ROOT_ENV" SKIP_ROOT_ENV
check_overwrite "$BACKEND_ENV" SKIP_BACKEND_ENV

# =============================================================================
# 4. コア設定 (DB / AI / エージェント)
# =============================================================================
section "コア設定 (DB / AI / エージェント)"

echo -e "${BOLD}[1/5] Supabase DATABASE_URL${NC}"
link "Supabase プロジェクト → Settings → Database → Connection string (URI)"
echo "  形式: postgresql://postgres:[PASSWORD]@db.[PROJECT_ID].supabase.co:5432/postgres"
read_input DB_URL "DATABASE_URL:" ""
echo

echo -e "${BOLD}[2/5] Anthropic API Key (Claude)${NC}"
link "https://console.anthropic.com/settings/keys"
read_input ANTHROPIC_KEY "ANTHROPIC_API_KEY (sk-ant-...):" "" "true"
echo

echo -e "${BOLD}[3/5] OpenAI API Key (Whisper 文字起こし)${NC}"
link "https://platform.openai.com/api-keys"
echo "  ※ 文字起こし機能を使わない場合はスキップ可"
read_input OPENAI_KEY "OPENAI_API_KEY (sk-...):" "" "true"
echo

echo -e "${BOLD}[4/5] Agent API Key${NC}"
AUTO_AGENT_KEY=$(generate_secret)
echo "  AIエージェントが /api/agent/* を叩く際に使う秘密鍵 (X-Agent-Api-Key ヘッダー)"
echo "  自動生成値: ${AUTO_AGENT_KEY}"
read_input AGENT_KEY "AGENT_API_KEY (Enter で自動生成値):" "$AUTO_AGENT_KEY"
echo

echo -e "${BOLD}[5/5] Agent Webhook URL${NC}"
echo "  AIエージェントへの通知先URL (Make, n8n 等)。不要な場合はスキップ可。"
read_input WEBHOOK_URL "AGENT_WEBHOOK_URL:" ""
echo

# =============================================================================
# 5. 外部API連携 (OAuth 2.0)
# =============================================================================
section "外部API連携 (OAuth 2.0) — 使う連携だけ設定してください"

echo -e "  各サービスのOAuthアプリを作成し、${BOLD}Client ID${NC} と ${BOLD}Client Secret${NC} を取得してください。"
echo -e "  コールバックURL: ${CYAN}http://localhost:8000/api/oauth/callback${NC}"
echo -e "  スキップしたい場合は Enter をそのまま押してください。\n"

# ---------- Slack ----------
echo -e "${BOLD}─── Slack ─────────────────────────────────────────────────${NC}"
link "https://api.slack.com/apps → Create New App → OAuth & Permissions"
echo "  Redirect URL: http://localhost:8000/api/oauth/callback"
echo "  必要スコープ: chat:write, channels:read"
read_input SLACK_CLIENT_ID "SLACK_CLIENT_ID:" ""
read_input SLACK_CLIENT_SECRET "SLACK_CLIENT_SECRET:" "" "true"
echo

# ---------- Microsoft Teams ----------
echo -e "${BOLD}─── Microsoft Teams ────────────────────────────────────────${NC}"
link "https://portal.azure.com → Azure Active Directory → App registrations → New registration"
echo "  Redirect URI: http://localhost:8000/api/oauth/callback"
echo "  必要権限: Chat.ReadWrite (Microsoft Graph)"
read_input TEAMS_CLIENT_ID "TEAMS_CLIENT_ID (Azure アプリケーション ID):" ""
read_input TEAMS_CLIENT_SECRET "TEAMS_CLIENT_SECRET (クライアントシークレット):" "" "true"
echo

# ---------- Zoom ----------
echo -e "${BOLD}─── Zoom ───────────────────────────────────────────────────${NC}"
link "https://marketplace.zoom.us/develop/create → OAuth App"
echo "  Redirect URL: http://localhost:8000/api/oauth/callback"
echo "  必要スコープ: meeting:read, meeting:write"
read_input ZOOM_CLIENT_ID "ZOOM_CLIENT_ID:" ""
read_input ZOOM_CLIENT_SECRET "ZOOM_CLIENT_SECRET:" "" "true"
echo

# ---------- Google (Meet + Gmail 共通) ----------
echo -e "${BOLD}─── Google (Meet / Gmail 共通) ─────────────────────────────${NC}"
link "https://console.cloud.google.com → APIs & Services → Credentials → Create OAuth 2.0 Client ID"
echo "  Authorized redirect URI: http://localhost:8000/api/oauth/callback"
echo "  有効にするAPI: Google Calendar API, Gmail API"
echo "  ※ Google Meet と Gmail で同じ Client ID / Secret を共有します"
read_input GOOGLE_CLIENT_ID "GOOGLE_CLIENT_ID:" ""
read_input GOOGLE_CLIENT_SECRET "GOOGLE_CLIENT_SECRET:" "" "true"
echo

# ---------- Salesforce ----------
echo -e "${BOLD}─── Salesforce ─────────────────────────────────────────────${NC}"
link "Salesforce Setup → Apps → App Manager → New Connected App"
echo "  Callback URL: http://localhost:8000/api/oauth/callback"
echo "  必要スコープ: api, refresh_token"
read_input SALESFORCE_CLIENT_ID "SALESFORCE_CLIENT_ID (Consumer Key):" ""
read_input SALESFORCE_CLIENT_SECRET "SALESFORCE_CLIENT_SECRET (Consumer Secret):" "" "true"
echo

# ---------- HubSpot ----------
echo -e "${BOLD}─── HubSpot ────────────────────────────────────────────────${NC}"
link "https://developers.hubspot.com → Apps → Create app → Auth"
echo "  Redirect URL: http://localhost:8000/api/oauth/callback"
echo "  必要スコープ: contacts, crm.objects.deals.read"
read_input HUBSPOT_CLIENT_ID "HUBSPOT_CLIENT_ID:" ""
read_input HUBSPOT_CLIENT_SECRET "HUBSPOT_CLIENT_SECRET:" "" "true"
echo

# =============================================================================
# 6. .env ファイルへの書き込み
# =============================================================================
section ".env ファイルへの書き込み"

write_env() {
  local filepath="$1"
  cat > "$filepath" <<EOF
# deal_foward 環境変数
# 生成日時: $(date '+%Y-%m-%d %H:%M:%S')
# このファイルをGitにコミットしないでください

# =============================================================================
# コア設定
# =============================================================================
DATABASE_URL=${DB_URL}
ANTHROPIC_API_KEY=${ANTHROPIC_KEY}
OPENAI_API_KEY=${OPENAI_KEY}
AGENT_API_KEY=${AGENT_KEY}
AGENT_WEBHOOK_URL=${WEBHOOK_URL}

# =============================================================================
# 外部API連携 (OAuth 2.0)
# =============================================================================

# Slack
# https://api.slack.com/apps
SLACK_CLIENT_ID=${SLACK_CLIENT_ID}
SLACK_CLIENT_SECRET=${SLACK_CLIENT_SECRET}

# Microsoft Teams (Azure AD)
# https://portal.azure.com
TEAMS_CLIENT_ID=${TEAMS_CLIENT_ID}
TEAMS_CLIENT_SECRET=${TEAMS_CLIENT_SECRET}

# Zoom
# https://marketplace.zoom.us/develop/create
ZOOM_CLIENT_ID=${ZOOM_CLIENT_ID}
ZOOM_CLIENT_SECRET=${ZOOM_CLIENT_SECRET}

# Google (Meet + Gmail 共通)
# https://console.cloud.google.com
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}

# Salesforce
# Salesforce Setup → Connected Apps
SALESFORCE_CLIENT_ID=${SALESFORCE_CLIENT_ID}
SALESFORCE_CLIENT_SECRET=${SALESFORCE_CLIENT_SECRET}

# HubSpot
# https://developers.hubspot.com
HUBSPOT_CLIENT_ID=${HUBSPOT_CLIENT_ID}
HUBSPOT_CLIENT_SECRET=${HUBSPOT_CLIENT_SECRET}
EOF
}

if [ "$SKIP_ROOT_ENV" = "false" ]; then
  write_env "$ROOT_ENV"
  success "${ROOT_ENV} を作成しました"
fi

if [ "$SKIP_BACKEND_ENV" = "false" ]; then
  write_env "$BACKEND_ENV"
  success "${BACKEND_ENV} を作成しました"
fi

# =============================================================================
# 7. .gitignore 確認
# =============================================================================
section ".gitignore 確認"

check_gitignore() {
  local gitignore="$1"
  if [ -f "$gitignore" ] && grep -q "\.env" "$gitignore" 2>/dev/null; then
    success "${gitignore}: .env は除外設定済み"
  elif [ -f "$gitignore" ]; then
    printf '\n.env\n.env.*\n' >> "$gitignore"
    warn "${gitignore} に .env を追加しました (シークレット漏洩防止)"
  fi
}

check_gitignore ".gitignore"
check_gitignore "backend/.gitignore" 2>/dev/null || true

# =============================================================================
# 8. 連携設定サマリー
# =============================================================================
section "連携設定サマリー"

show_status() {
  local name="$1"; local val="$2"
  if [ -n "$val" ]; then
    echo -e "  ${GREEN}✓${NC} ${name}"
  else
    echo -e "  ${YELLOW}–${NC} ${name} (未設定 — 後で .env を編集して追加可能)"
  fi
}

show_status "Slack"            "$SLACK_CLIENT_ID"
show_status "Microsoft Teams"  "$TEAMS_CLIENT_ID"
show_status "Zoom"             "$ZOOM_CLIENT_ID"
show_status "Google Meet/Gmail" "$GOOGLE_CLIENT_ID"
show_status "Salesforce"       "$SALESFORCE_CLIENT_ID"
show_status "HubSpot"          "$HUBSPOT_CLIENT_ID"

echo
echo -e "  OAuthフローの開始: ${CYAN}http://localhost:8000/api/oauth/:service/authorize${NC}"
echo -e "  例 (Slack):        ${CYAN}http://localhost:8000/api/oauth/slack/authorize${NC}"
echo -e "  コールバックURL:   ${CYAN}http://localhost:8000/api/oauth/callback${NC}"

# =============================================================================
# 9. 依存パッケージのインストール
# =============================================================================
section "依存パッケージのインストール"

if [ "$USE_DOCKER" = "false" ]; then
  info "Bundler で gem をインストール中..."
  cd backend
  if command_exists rbenv; then
    export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"
  fi
  bundle install
  success "gem のインストール完了"
  cd ..

  info "npm でパッケージをインストール中..."
  cd frontend
  npm install
  success "npm パッケージのインストール完了"
  cd ..
else
  info "Docker モードのため、パッケージは起動時にインストールされます"
fi

# =============================================================================
# 10. データベースマイグレーション
# =============================================================================
section "データベース設定"

if [ -n "$DB_URL" ]; then
  if [ "$USE_DOCKER" = "false" ]; then
    info "DB マイグレーションを実行します..."
    cd backend
    if command_exists rbenv; then
      export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"
    fi
    if bundle exec rails db:migrate 2>&1; then
      success "DB マイグレーション完了"
    else
      warn "DB マイグレーションでエラーが発生しました。DATABASE_URL を確認してください"
    fi
    cd ..
  else
    info "Docker モードでは起動後に自動マイグレーションが実行されます"
  fi
else
  warn "DATABASE_URL が未設定のためマイグレーションをスキップします"
  warn "後で .env を設定してから手動実行してください:"
  echo "    cd backend && bundle exec rails db:migrate"
fi

# =============================================================================
# 11. 起動
# =============================================================================
section "セットアップ完了"

echo "  以下のコマンドで起動できます:"
echo

if [ "$USE_DOCKER" = "true" ]; then
  echo -e "  ${BOLD}起動:${NC}      ${COMPOSE_CMD} up --build"
  echo -e "  ${BOLD}BG起動:${NC}    ${COMPOSE_CMD} up -d --build"
  echo -e "  ${BOLD}停止:${NC}      ${COMPOSE_CMD} down"
else
  echo -e "  ${BOLD}バックエンド:${NC} cd backend && bundle exec rails server -p 8000"
  echo -e "  ${BOLD}フロントエンド:${NC} cd frontend && npm run dev"
fi

echo
echo -e "  ${BOLD}アクセス先:${NC}"
echo "    フロントエンド : http://localhost:5173"
echo "    バックエンドAPI: http://localhost:8000/api"
echo "    ヘルスチェック : http://localhost:8000/api/health"
echo
echo -e "  ${BOLD}OAuth 連携開始例:${NC}"
echo "    http://localhost:8000/api/oauth/slack/authorize"
echo "    http://localhost:8000/api/oauth/google_meet/authorize"
echo "    http://localhost:8000/api/oauth/gmail/authorize"
echo

read -rp "  今すぐ起動しますか? [y/N]: " START_NOW
if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
  echo
  if [ "$USE_DOCKER" = "true" ]; then
    info "${COMPOSE_CMD} up --build を実行します..."
    eval "$COMPOSE_CMD up --build"
  else
    info "バックエンドとフロントエンドをバックグラウンドで起動します..."
    cd backend
    if command_exists rbenv; then
      export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"
    fi
    bundle exec rails server -p 8000 &
    RAILS_PID=$!
    cd ..
    cd frontend
    npm run dev &
    VITE_PID=$!
    cd ..
    success "起動しました (Rails PID: ${RAILS_PID}, Vite PID: ${VITE_PID})"
    info "停止するには Ctrl+C を押してください"
    wait $RAILS_PID $VITE_PID
  fi
fi

echo
success "セットアップ完了! deal_foward へようこそ"
