# CLAUDE.md — deal_foward AIアシスタントガイド

> このファイルは、本リポジトリで作業するAIアシスタント向けのコンテキスト情報を提供します。

## プロジェクト概要

**deal_foward** は **営業AIエージェントと人間をつなぐコミュニケーションプラットフォーム**です。

- 営業AIエージェントがAPIを通して通信情報を取得し、営業活動を自律実行
- プラットフォームはAIエージェントの報告内容を保存し、AIが提示するプレイブックを可視化
- 人間はダッシュボードでAIの活動を監視・承認・支援

**フロー:**
```
サイト埋め込みチャットbot → リード検知 → AIがSlack/Teams分析
    → 商談MTG参加・録画 → プレイブック自動生成
    → エージェントがプレイブック実行・監視 → 人間がダッシュボードで把握
```

**リポジトリ:** `sinoue-1003/deal_foward`

## 技術スタック

- **バックエンド:** Ruby on Rails 8.1 (API mode) / PostgreSQL (Supabase)
- **フロントエンド:** React 18 / Vite / Tailwind CSS / Recharts / Lucide React
- **AI連携:** Claude API (`anthropic` gem) / OpenAI Whisper (`ruby-openai` gem)

## リポジトリの状態

- **現在の状態:** 実装済み — Railsバックエンド・フロントエンドUI完備
- **メインブランチ:** master
- **開発ブランチ:** `claude/<説明>-<セッションID>` パターン

## ディレクトリ構成

```
deal_foward/
├── CLAUDE.md
├── backend/                # Ruby on Rails 8.1 API
│   ├── Gemfile
│   ├── .env.example
│   ├── config/
│   │   ├── routes.rb
│   │   ├── database.yml
│   │   └── initializers/cors.rb
│   ├── app/
│   │   ├── controllers/api/
│   │   │   ├── agent/actions_controller.rb  # AIエージェント専用API
│   │   │   ├── chatbot_sessions_controller.rb
│   │   │   ├── playbooks_controller.rb
│   │   │   ├── communications_controller.rb
│   │   │   ├── integrations_controller.rb
│   │   │   ├── deals_controller.rb
│   │   │   └── dashboard/
│   │   ├── models/               # ActiveRecord models
│   │   └── services/
│   │       ├── ai_analysis_service.rb
│   │       ├── chatbot_service.rb
│   │       ├── playbook_generator_service.rb
│   │       └── webhook_notifier_service.rb
│   └── db/migrate/               # 9テーブルのマイグレーション
└── frontend/                     # React + Vite
    └── src/
        ├── App.jsx
        ├── hooks/useApi.js
        ├── components/
        │   ├── StatCard.jsx
        │   ├── ChannelBadge.jsx
        │   ├── IntentBadge.jsx
        │   ├── PlaybookStepItem.jsx
        │   └── StageBadge.jsx
        └── pages/
            ├── Dashboard.jsx
            ├── Chatbot.jsx / ChatbotDetail.jsx
            ├── Playbooks.jsx / PlaybookDetail.jsx
            ├── Communications.jsx
            ├── Deals.jsx / DealDetail.jsx
            └── Analytics.jsx
```

## 機能一覧

1. **通信API連携** — Slack, Teams, Zoom, Google Meet, Salesforce, HubSpot
2. **ダッシュボード** — AIエージェント活動・パイプライン・連携ステータス
3. **チャットbot** — サイト埋め込みbot、インテント検知、自動プレイブック生成
4. **営業プレイブック** — AIが生成、人間とAIが状況と次アクションを共有するビュー

## AIエージェント向けAPI

```
# エージェント認証: X-Agent-Api-Key ヘッダー
POST /api/agent/report                    # 活動報告
POST /api/agent/request_context           # 会社の全コンテキスト取得
POST /api/agent/trigger_playbook          # プレイブック生成依頼
GET  /api/agent/communications            # 通信データ取得
GET  /api/agent/playbook/:id              # プレイブック + status_summary取得
PATCH /api/agent/playbook/:id/step/:n     # ステップ完了報告
```

プレイブックの `status_summary` フィールドにAIと人間の共有コンテキスト情報が含まれます。

## 開発ワークフロー

### 起動

```bash
./start.sh                    # バックエンド + フロントエンド同時起動
```

### 個別起動

```bash
# Rails バックエンド
cd backend
export PATH="/opt/rbenv/versions/3.3.6/bin:$PATH"
bundle exec rails db:migrate
bundle exec rails server -p 8000

# フロントエンド
cd frontend && npm run dev
```

### 環境変数

`backend/.env.example` をコピーして `backend/.env` を作成:
```
DATABASE_URL=postgresql://...
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
AGENT_API_KEY=your-agent-api-key
AGENT_WEBHOOK_URL=https://your-webhook-url.com/webhook
```

## AIアシスタント向けガイドライン

1. **まずこのファイルを読む** — 変更前にプロジェクトのコンテキストを把握する
2. **既存パターンに従う** — Rails規約 (コントローラー/モデル/サービスの分離) を維持
3. **シークレットをコミットしない** — APIキー、DBパスワードは.envで管理
4. **作成より編集を優先する** — 既存ファイルを修正する
5. **AIエージェントフレンドリー設計** — `/api/agent/*` エンドポイントはエージェントが使いやすい形式を維持


## Workflow Orchestration

### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.