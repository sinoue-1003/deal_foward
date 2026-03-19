# タスク管理

このファイルはセッションごとのタスク管理に使います。
完了したら `[x]` にチェックしてください。

---

## テンプレート

```markdown
## [YYYY-MM-DD] タスク名

### 計画
- [ ] ステップ1
- [ ] ステップ2
- [ ] ステップ3

### 確認事項
- 変更したファイル:
- テスト実行結果:
- 気づいた点:

### レビュー
- 完了: [yes/no]
- lessons.md 更新: [yes/no]
```

---

## 完了済みタスク

### [2026-03-19] Claude Code ベストプラクティス設定の追加

- [x] `.claude/settings.json` 作成（言語・権限・hooks）
- [x] カスタムスラッシュコマンド追加（migrate / test / lint / dev / routes）
- [x] `tasks/lessons.md` 作成
- [x] `tasks/todo.md` 作成

変更ファイル:
- `.claude/settings.json` (新規)
- `.claude/commands/migrate.md` (新規)
- `.claude/commands/test.md` (新規)
- `.claude/commands/lint.md` (新規)
- `.claude/commands/dev.md` (新規)
- `.claude/commands/routes.md` (新規)
- `tasks/lessons.md` (新規)
- `tasks/todo.md` (新規)
