# /dev — 開発サーバー起動状態確認

バックエンド・フロントエンドのプロセス状態を確認します。

```bash
# プロセス確認
pgrep -a -f "rails server" || echo "Rails server: NOT running"
pgrep -a -f "vite" || echo "Vite dev server: NOT running"

# ポート確認
lsof -i :8000 2>/dev/null | head -5 || echo "Port 8000: not in use"
lsof -i :5173 2>/dev/null | head -5 || echo "Port 5173: not in use"
```

サーバーが起動していない場合は `./start.sh` で起動できることを伝えてください。
ログにエラーがあれば調査して対処方法を提案してください。
