#!/bin/bash
set -e

echo "=== DealForward 起動スクリプト ==="

# Backend
echo "[1/2] バックエンドを起動中..."
cd "$(dirname "$0")/backend"

if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install -q -r requirements.txt

if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

mkdir -p data/uploads
uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!
echo "  バックエンド起動: http://localhost:8000 (PID: $BACKEND_PID)"

# Frontend
echo "[2/2] フロントエンドを起動中..."
cd "$(dirname "$0")/frontend"

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
