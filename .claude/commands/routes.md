# /routes — APIルート一覧

Railsのルーティングを確認します。

```bash
cd backend
export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"
bundle exec rails routes --expanded 2>&1 | grep -E "(api|agent)" | head -60
```

エージェント向けAPI (`/api/agent/*`) と人間向けAPI を整理して一覧表示してください。
