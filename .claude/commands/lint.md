# /lint — コード品質チェック

バックエンド（Rubocop）とフロントエンドの静的解析を実行します。

## バックエンド (Rubocop)

```bash
cd backend
export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"
bundle exec rubocop --format simple 2>&1
```

## フロントエンド (ESLint)

```bash
cd frontend
npm run lint 2>&1
```

違反があれば一覧を表示し、自動修正可能なものは `--autocorrect` / `--fix` オプションで修正するか確認してください。
