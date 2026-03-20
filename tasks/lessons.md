# Lessons Learned

AIアシスタントが作業中に学んだパターンと注意事項を記録します。
同じミスを繰り返さないためのルール集。

---

## Rails / Ruby

<!-- 例:
- `bundle exec rails` は必ず `backend/` ディレクトリで実行する
- rbenv を使うため PATH に `/opt/rbenv/versions/3.3.6/bin` を追加する必要がある
-->

## フロントエンド (React / Vite)

<!-- 例:
- npm コマンドは `frontend/` ディレクトリで実行する
-->

## Git / ブランチ戦略

- ブランチ名は `claude/<説明>-<セッションID>` パターンに従う
- `git push --force` は禁止（設定でブロック済み）
- シークレット（.env, APIキー）はコミットしない

## Claude Code 設定

- カスタムコマンドは `.claude/commands/*.md` に追加する
- hooks は `.claude/settings.json` で管理する
- lessons はセッション終了時に更新する（Stop hookでリマインダーあり）

---

_最終更新: 2026-03-19_
