# /migrate — DBマイグレーション実行

Railsのデータベースマイグレーションを実行します。

```bash
cd backend
export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"
bundle exec rails db:migrate
bundle exec rails db:migrate:status
```

マイグレーション後、現在のスキーマ状態を確認して報告してください。
エラーが発生した場合は原因を調査して修正方法を提案してください。
