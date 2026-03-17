#!/bin/bash
set -e

echo "=== Deal Forward 起動スクリプト ==="

SCRIPT_DIR="$(dirname "$0")"

# Rails Backend
echo "[1/2] Rails バックエンドを起動中..."
cd "$SCRIPT_DIR/backend"

export PATH="/opt/rbenv/versions/3.3.6/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

if [ ! -f "Gemfile.lock" ]; then
  bundle _2.5.0_ install
fi

if [ -f ".env" ]; then
  set -a
  source .env
  set +a
fi

bundle _2.5.0_ exec rails db:migrate 2>/dev/null || echo "  (DB migration skipped - check DATABASE_URL)"
bundle _2.5.0_ exec rails server -p 8000 -b 0.0.0.0 &
BACKEND_PID=$!
echo "  Rails API起動: http://localhost:8000 (PID: $BACKEND_PID)"

# Frontend
echo "[2/2] フロントエンドを起動中..."
cd "$SCRIPT_DIR/frontend"

if [ ! -d "node_modules" ]; then
  npm install
fi

npm run dev &
FRONTEND_PID=$!
echo "  フロントエンド起動: http://localhost:5173 (PID: $FRONTEND_PID)"

echo ""
echo "=== 起動完了 ==="
echo "  アプリ: http://localhost:5173"
echo "  API:   http://localhost:8000"
echo "  Ctrl+C で停止"

trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM
wait
