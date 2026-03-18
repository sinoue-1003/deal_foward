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
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}\n"; }
prompt()  { echo -e "${YELLOW}$1${NC}"; }

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
  local description="$2"
  local default_val="${3:-}"
  local is_secret="${4:-false}"

  if [ -n "$default_val" ]; then
    prompt "  ${description}"
    prompt "  (Enter でスキップ → デフォルト値を使用: ${default_val})"
  else
    prompt "  ${description}"
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

  eval "$var_name='$input_val'"
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
    # Docker Compose v2 (docker compose) or v1 (docker-compose)
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
  # Ruby チェック
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

  # Node.js チェック
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

# psql (DB確認用、任意)
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
# 3. .env ファイル作成
# =============================================================================
section ".env ファイル設定"

ROOT_ENV=".env"
BACKEND_ENV="backend/.env"

# --- ルート .env (Docker Compose 用) ---
if [ -f "$ROOT_ENV" ]; then
  warn "${ROOT_ENV} が既に存在します"
  read -rp "  上書きしますか? [y/N]: " OVERWRITE_ROOT
  if [[ ! "$OVERWRITE_ROOT" =~ ^[Yy]$ ]]; then
    info "既存の ${ROOT_ENV} を維持します"
    SKIP_ROOT_ENV=true
  else
    SKIP_ROOT_ENV=false
  fi
else
  SKIP_ROOT_ENV=false
fi

# --- backend/.env (ローカル起動 / Rails 用) ---
if [ -f "$BACKEND_ENV" ]; then
  warn "${BACKEND_ENV} が既に存在します"
  read -rp "  上書きしますか? [y/N]: " OVERWRITE_BACKEND
  if [[ ! "$OVERWRITE_BACKEND" =~ ^[Yy]$ ]]; then
    info "既存の ${BACKEND_ENV} を維持します"
    SKIP_BACKEND_ENV=true
  else
    SKIP_BACKEND_ENV=false
  fi
else
  SKIP_BACKEND_ENV=false
fi

# =============================================================================
# 4. API キー入力
# =============================================================================
section "API キー / 環境変数の設定"

echo -e "  以下のサービスのAPIキーを入力してください。"
echo -e "  スキップしたい項目は Enter を押してください (後で .env を直接編集できます)。\n"

# --- DATABASE_URL ---
echo -e "${BOLD}[1/5] Supabase DATABASE_URL${NC}"
echo "  Supabase プロジェクト → Settings → Database → Connection string (URI)"
echo "  形式: postgresql://postgres:[PASSWORD]@db.[PROJECT_ID].supabase.co:5432/postgres"
read_input DB_URL "DATABASE_URL を入力:" ""
echo

# --- ANTHROPIC_API_KEY ---
echo -e "${BOLD}[2/5] Anthropic API Key (Claude)${NC}"
echo "  取得先: https://console.anthropic.com/settings/keys"
read_input ANTHROPIC_KEY "ANTHROPIC_API_KEY を入力 (sk-ant-...):" "" "true"
echo

# --- OPENAI_API_KEY ---
echo -e "${BOLD}[3/5] OpenAI API Key (Whisper 文字起こし用)${NC}"
echo "  取得先: https://platform.openai.com/api-keys"
echo "  ※ 文字起こし機能を使わない場合はスキップ可"
read_input OPENAI_KEY "OPENAI_API_KEY を入力 (sk-...):" "" "true"
echo

# --- AGENT_API_KEY ---
echo -e "${BOLD}[4/5] Agent API Key (AIエージェント認証用)${NC}"
AUTO_AGENT_KEY=$(generate_secret)
echo "  AIエージェントが /api/agent/* を叩く際に使う秘密鍵です。"
echo "  自動生成値: ${AUTO_AGENT_KEY}"
read_input AGENT_KEY "AGENT_API_KEY を入力 (Enter で自動生成値を使用):" "$AUTO_AGENT_KEY"
echo

# --- AGENT_WEBHOOK_URL ---
echo -e "${BOLD}[5/5] Agent Webhook URL (任意)${NC}"
echo "  AIエージェントへの通知先URL (Make, n8n 等)。不要な場合はスキップ可。"
read_input WEBHOOK_URL "AGENT_WEBHOOK_URL を入力:" ""
echo

# =============================================================================
# 5. .env ファイルへの書き込み
# =============================================================================
section ".env ファイルへの書き込み"

write_env() {
  local filepath="$1"
  local db_url="$2"
  local anthropic_key="$3"
  local openai_key="$4"
  local agent_key="$5"
  local webhook_url="$6"

  cat > "$filepath" <<EOF
# deal_foward 環境変数
# 生成日時: $(date '+%Y-%m-%d %H:%M:%S')
# このファイルをGitにコミットしないでください

DATABASE_URL=${db_url}
ANTHROPIC_API_KEY=${anthropic_key}
OPENAI_API_KEY=${openai_key}
AGENT_API_KEY=${agent_key}
AGENT_WEBHOOK_URL=${webhook_url}
EOF
}

if [ "$SKIP_ROOT_ENV" = "false" ]; then
  write_env "$ROOT_ENV" "$DB_URL" "$ANTHROPIC_KEY" "$OPENAI_KEY" "$AGENT_KEY" "$WEBHOOK_URL"
  success "${ROOT_ENV} を作成しました"
fi

if [ "$SKIP_BACKEND_ENV" = "false" ]; then
  write_env "$BACKEND_ENV" "$DB_URL" "$ANTHROPIC_KEY" "$OPENAI_KEY" "$AGENT_KEY" "$WEBHOOK_URL"
  success "${BACKEND_ENV} を作成しました"
fi

# =============================================================================
# 6. .gitignore 確認
# =============================================================================
section ".gitignore 確認"

check_gitignore() {
  local gitignore="$1"
  local pattern="$2"
  if [ -f "$gitignore" ] && grep -q "$pattern" "$gitignore"; then
    success "${gitignore}: .env は除外設定済み"
  elif [ -f "$gitignore" ]; then
    echo ".env" >> "$gitignore"
    echo ".env.*" >> "$gitignore"
    warn "${gitignore} に .env を追加しました (シークレット漏洩防止)"
  fi
}

check_gitignore ".gitignore" "\.env"
check_gitignore "backend/.gitignore" "\.env" 2>/dev/null || true

# =============================================================================
# 7. 依存パッケージのインストール
# =============================================================================
section "依存パッケージのインストール"

if [ "$USE_DOCKER" = "false" ]; then
  # --- Ruby gems ---
  info "Bundler で gem をインストール中..."
  cd backend
  if command_exists rbenv; then
    export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"
  fi
  bundle install
  success "gem のインストール完了"
  cd ..

  # --- Node modules ---
  info "npm でパッケージをインストール中..."
  cd frontend
  npm install
  success "npm パッケージのインストール完了"
  cd ..
else
  info "Docker モードのため、パッケージは起動時にインストールされます"
fi

# =============================================================================
# 8. データベースマイグレーション
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
  warn "後で .env に DATABASE_URL を設定し、手動で実行してください:"
  echo "    cd backend && bundle exec rails db:migrate"
fi

# =============================================================================
# 9. 起動
# =============================================================================
section "起動"

echo "  セットアップが完了しました!"
echo
echo "  以下のコマンドで起動できます:"
echo

if [ "$USE_DOCKER" = "true" ]; then
  echo -e "  ${BOLD}Docker Compose:${NC}"
  echo "    ${COMPOSE_CMD} up --build"
  echo
  echo -e "  ${BOLD}バックグラウンドで起動:${NC}"
  echo "    ${COMPOSE_CMD} up -d --build"
  echo
  echo -e "  ${BOLD}停止:${NC}"
  echo "    ${COMPOSE_CMD} down"
else
  echo -e "  ${BOLD}バックエンド (Rails):${NC}"
  echo "    cd backend && bundle exec rails server -p 8000"
  echo
  echo -e "  ${BOLD}フロントエンド (Vite):${NC}"
  echo "    cd frontend && npm run dev"
fi

echo
echo -e "  ${BOLD}アクセス先:${NC}"
echo "    フロントエンド : http://localhost:5173"
echo "    バックエンドAPI: http://localhost:8000/api"
echo "    ヘルスチェック : http://localhost:8000/api/health"
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
success "セットアップ完了! deal_foward へようこそ 🚀"
