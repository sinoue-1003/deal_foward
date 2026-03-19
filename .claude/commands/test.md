# /test — テスト実行

RSpecでバックエンドのテストを実行します。引数があれば特定のファイルを実行します。

```bash
cd backend
export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"
bundle exec rspec $ARGUMENTS --format documentation 2>&1
```

テスト結果をまとめて報告してください。
失敗したテストがあれば原因を分析し、修正案を提示してください。
