# deal_foward — 仕様・機能ドキュメント

> 最終更新: 2026-03-17

## 目次

1. [プロジェクト概要](#1-プロジェクト概要)
2. [技術スタック](#2-技術スタック)
3. [データベース設計](#3-データベース設計)
4. [APIエンドポイント仕様](#4-apiエンドポイント仕様)
5. [バックエンドサービス](#5-バックエンドサービス)
6. [フロントエンド構成](#6-フロントエンド構成)
7. [主要ワークフロー](#7-主要ワークフロー)
8. [環境変数・設定](#8-環境変数設定)

---

## 1. プロジェクト概要

**deal_foward** は、営業AIエージェントと人間の営業チームをつなぐコミュニケーションプラットフォームです。

### 解決する課題

- AIエージェントによる営業活動の自律実行
- 人間がAIの活動をリアルタイムで監視・承認
- 複数チャネル（Slack, Teams, Zoom 等）の通信を統合分析
- AI生成プレイブックによる再現性ある営業プロセスの確立

### システムフロー

```
サイト埋め込みチャットbot
    ↓ リード検知・インテント分析
AIエージェントが Slack/Teams/Zoom を分析
    ↓
商談MTG参加・録画・トランスクリプト生成
    ↓
プレイブック自動生成（Claude API）
    ↓
エージェントがプレイブック実行（各ステップ完了報告）
    ↓
人間がダッシュボードで活動把握・次アクション承認
```

---

## 2. 技術スタック

| レイヤー | 技術 | バージョン |
|---------|------|---------|
| バックエンド | Ruby on Rails (API mode) | 8.1.2 |
| データベース | PostgreSQL (Supabase) | — |
| フロントエンド | React + Vite + Tailwind CSS | 18 / 5 / 3 |
| グラフ | Recharts | — |
| アイコン | Lucide React | — |
| AIチャット分析 | Claude API (`anthropic` gem) | `claude-sonnet-4-6` |
| 音声文字起こし | OpenAI Whisper (`ruby-openai` gem) | — |
| Webhook通知 | HTTParty | — |
| ルーティング | React Router | v6 |

---

## 3. データベース設計

全テーブルは **UUID主キー**（`gen_random_uuid()` デフォルト）を使用します。

### 3.1 companies（企業）

| カラム | 型 | 制約 | 説明 |
|-------|---|------|------|
| id | UUID | PK | |
| name | string | NOT NULL | 企業名 |
| industry | string | | 業界 |
| website | string | | ウェブサイト |
| size | string | | 企業規模 |
| crm_id | string | | CRM連携ID |
| source | string | | 流入元 |
| created_at / updated_at | datetime | | |

**リレーション:**
- `has_many :contacts`
- `has_many :chat_sessions`
- `has_many :communications`
- `has_many :agent_reports`
- `has_many :playbooks`
- `has_many :deals`

---

### 3.2 contacts（コンタクト）

| カラム | 型 | 制約 | 説明 |
|-------|---|------|------|
| id | UUID | PK | |
| company_id | UUID | FK | |
| name | string | NOT NULL | 担当者名 |
| email | string | | メールアドレス |
| role | string | | 役職 |
| source_channel | string | | 接触チャネル |
| created_at / updated_at | datetime | | |

**リレーション:**
- `belongs_to :company` (optional)
- `has_many :chat_sessions, :communications, :agent_reports, :playbooks, :deals`

---

### 3.3 chat_sessions（チャットセッション）

| カラム | 型 | 制約 | 説明 |
|-------|---|------|------|
| id | UUID | PK | |
| contact_id | UUID | FK | |
| company_id | UUID | FK | |
| messages | JSONB | default: [] | `[{role, content, timestamp}]` |
| intent_score | integer | default: 0 | 購買意向スコア（0-100） |
| status | string | default: "active" | active / ended / converted |
| ended_at | datetime | | セッション終了日時 |
| created_at / updated_at | datetime | | |

**インスタンスメソッド:**
- `intent_level` → `hot`（80+）/ `warm`（60-79）/ `cool`（40-59）/ `cold`（40未満）

---

### 3.4 communications（通信データ）

| カラム | 型 | 制約 | 説明 |
|-------|---|------|------|
| id | UUID | PK | |
| company_id | UUID | FK | |
| contact_id | UUID | FK | |
| channel | string | NOT NULL | slack / teams / zoom / google_meet / email / salesforce / hubspot |
| content | text | | 通信内容 |
| summary | text | | AI生成サマリー |
| sentiment | string | | positive / neutral / negative |
| keywords | JSONB | default: [] | キーワード配列（最大10） |
| action_items | JSONB | default: [] | アクション項目配列（最大5） |
| recorded_at | datetime | | 通信日時 |
| analyzed_at | datetime | | AI分析完了日時 |
| created_at / updated_at | datetime | | |

**インデックス:** `channel`

---

### 3.5 agent_reports（AIエージェント報告）

| カラム | 型 | 制約 | 説明 |
|-------|---|------|------|
| id | UUID | PK | |
| company_id | UUID | FK | |
| contact_id | UUID | FK | |
| action_taken | string | NOT NULL | 実行アクション |
| insights | JSONB | default: {} | インサイト情報 |
| next_recommended_actions | JSONB | default: [] | 次推奨アクション配列 |
| status | string | default: "pending" | pending / in_progress / completed |
| created_at / updated_at | datetime | | |

---

### 3.6 playbooks（プレイブック）

| カラム | 型 | 制約 | 説明 |
|-------|---|------|------|
| id | UUID | PK | |
| company_id | UUID | FK | |
| contact_id | UUID | FK | |
| title | string | NOT NULL | プレイブック名 |
| status | string | default: "active" | active / paused / completed |
| steps | JSONB | default: [] | ステップ配列（下記参照） |
| current_step | integer | default: 0 | 現在のステップインデックス |
| created_by | string | default: "ai_agent" | ai_agent / human |
| objective | text | | 目的・ゴール |
| situation_summary | text | | AI+人間共有コンテキスト |
| created_at / updated_at | datetime | | |

**インデックス:** `status`

**stepsの構造（各要素）:**
```json
{
  "step": 1,
  "action_type": "send_slack_message",
  "channel": "slack",
  "target": "担当者名",
  "template": "メッセージテンプレート",
  "due_in_hours": 24,
  "status": "pending",
  "result": null,
  "completed_at": null
}
```

**action_type 一覧:**
- `send_slack_message` — Slackメッセージ送信
- `schedule_meeting` — MTG設定
- `send_email` — メール送信
- `update_crm` — CRM更新
- `create_followup_task` — フォローアップタスク作成
- `send_proposal` — 提案書送付
- `request_demo` — デモ依頼
- `share_case_study` — 事例共有
- `follow_up_call` — フォローアップ電話

**インスタンスメソッド:**
- `current_step_info` → 現在ステップデータ
- `next_action` → 最初のpendingステップ
- `status_summary` → `{situation, progress, current_step, next_action, status}`

---

### 3.7 playbook_executions（プレイブック実行ログ）

| カラム | 型 | 制約 | 説明 |
|-------|---|------|------|
| id | UUID | PK | |
| playbook_id | UUID | FK | |
| step_index | integer | NOT NULL | ステップインデックス |
| status | string | | pending / in_progress / completed / failed / skipped |
| result | text | | 実行結果 |
| executed_by | string | | ai_agent または人間のユーザー名 |
| executed_at | datetime | | 実行日時 |
| created_at / updated_at | datetime | | |

---

### 3.8 deals（商談）

| カラム | 型 | 制約 | 説明 |
|-------|---|------|------|
| id | UUID | PK | |
| company_id | UUID | FK | |
| contact_id | UUID | FK | |
| title | string | NOT NULL | 商談名 |
| stage | string | default: "prospect" | prospect / qualify / demo / proposal / negotiation / closed_won / closed_lost |
| amount | decimal(15,2) | | 商談金額 |
| probability | integer | default: 0 | 成約確率（0-100%） |
| owner | string | | 担当者 |
| close_date | date | | 見込みクローズ日 |
| notes | text | | メモ |
| created_at / updated_at | datetime | | |

**インデックス:** `stage`

---

### 3.9 integrations（連携設定）

| カラム | 型 | 制約 | 説明 |
|-------|---|------|------|
| id | UUID | PK | |
| integration_type | string | NOT NULL, UNIQUE | slack / teams / zoom / google_meet / salesforce / hubspot |
| status | string | default: "disconnected" | connected / disconnected / error |
| config | JSONB | default: {} | OAuthトークン・APIキー等 |
| last_synced_at | datetime | | 最終同期日時 |
| error_message | string | | エラーメッセージ |
| created_at / updated_at | datetime | | |

---

## 4. APIエンドポイント仕様

### 共通仕様

- ベースURL: `http://localhost:8000/api` （開発環境）
- レスポンス形式: JSON
- エラーレスポンス: `{error: "メッセージ"}` + 適切なHTTPステータス

### 4.1 ヘルスチェック

```
GET /api/health
```

**レスポンス例:**
```json
{ "status": "ok" }
```

---

### 4.2 AIエージェント専用API

**認証:** リクエストヘッダーに `X-Agent-Api-Key` が必須です。

#### 活動報告

```
POST /api/agent/report
```

**リクエストボディ:**
```json
{
  "company_id": "uuid",
  "contact_id": "uuid",
  "action_taken": "Slackにフォローアップメッセージを送信",
  "insights": { "sentiment": "positive" },
  "next_recommended_actions": ["MTGを設定する"]
}
```

**レスポンス:** 作成されたAgentReportオブジェクト + Webhook通知

---

#### コンテキスト取得

```
POST /api/agent/request_context
```

**リクエストボディ:**
```json
{ "company_id": "uuid" }
```

**レスポンス:**
```json
{
  "company": { ... },
  "contacts": [ ... ],
  "recent_communications": [ ... ],
  "active_playbook": { ... },
  "deal": { ... },
  "recommended_next_action": "..."
}
```

---

#### プレイブック生成依頼

```
POST /api/agent/trigger_playbook
```

**リクエストボディ:**
```json
{
  "company_id": "uuid",
  "contact_id": "uuid"
}
```

**レスポンス:** 生成されたPlaybookオブジェクト

---

#### 通信データ取得

```
GET /api/agent/communications?company_id=uuid&channel=slack
```

**クエリパラメータ:**
- `company_id` (任意)
- `channel` (任意): slack / teams / zoom / google_meet / email / salesforce / hubspot

**レスポンス:** 最新20件の通信データ配列

---

#### コンタクト一覧取得

```
GET /api/agent/contacts/:company_id
```

---

#### プレイブック取得

```
GET /api/agent/playbook/:id
```

**レスポンス:** Playbookオブジェクト + `status_summary`フィールド

---

#### ステップ完了報告

```
PATCH /api/agent/playbook/:id/step/:step_index
```

**リクエストボディ:**
```json
{
  "status": "completed",
  "result": "Slackメッセージ送信完了。返信あり。"
}
```

---

### 4.3 チャットbotセッション

#### セッション一覧

```
GET /api/chatbot/sessions
```

**レスポンス:** 最新50件。各セッションに `intent_level`、メッセージ数を付加。

---

#### セッション詳細

```
GET /api/chatbot/sessions/:id
```

**レスポンス:** セッション + 関連する company / contact 情報

---

#### セッション作成

```
POST /api/chatbot/session
```

**リクエストボディ:**
```json
{
  "contact_id": "uuid",
  "company_id": "uuid"
}
```

---

#### メッセージ送信

```
POST /api/chatbot/sessions/:id/message
```

**リクエストボディ:**
```json
{ "message": "料金プランを教えてください" }
```

**レスポンス:**
```json
{
  "reply": "AIからの返答テキスト",
  "intent_score": 75
}
```

**内部動作:**
1. ChatbotServiceがClaudeに返答生成を依頼
2. 3往復ごとにインテントスコアを再計算
3. インテント≥70の場合: プレイブック自動生成 + Webhook通知

---

### 4.4 プレイブック

#### 一覧

```
GET /api/playbooks?status=active
```

**クエリパラメータ:**
- `status` (任意): active / paused / completed

**レスポンス:** 各プレイブックに `status_summary`、ステップ数、完了数を付加

---

#### 詳細

```
GET /api/playbooks/:id
```

**レスポンス:** プレイブック + 実行ログ(`executions`)一覧

---

#### AI+人間共有ステータス

```
GET /api/playbooks/:id/status
```

**レスポンス:**
```json
{
  "situation": "テキスト",
  "objective": "テキスト",
  "steps": [ ... ],
  "company": { ... },
  "contact": { ... }
}
```

---

#### 作成

```
POST /api/playbooks
```

---

#### 更新

```
PATCH /api/playbooks/:id
```

---

#### 人間によるステップ実行

```
POST /api/playbooks/:id/execute
```

**レスポンス:** 実行されたステップ情報 + PlaybookExecution作成

---

### 4.5 通信データ

#### 一覧

```
GET /api/communications?channel=slack&company_id=uuid
```

**クエリパラメータ:**
- `channel` (任意)
- `company_id` (任意)

最新50件を返す。

---

#### 詳細

```
GET /api/communications/:id
```

---

#### 作成（自動AI分析付き）

```
POST /api/communications
```

**リクエストボディ:**
```json
{
  "company_id": "uuid",
  "contact_id": "uuid",
  "channel": "slack",
  "content": "通信内容テキスト",
  "recorded_at": "2026-03-17T10:00:00Z"
}
```

`content` がある場合、AiAnalysisServiceにより自動分析されます。

---

#### 手動分析

```
POST /api/communications/analyze
```

**リクエストボディ:**
```json
{ "id": "uuid" }
```

---

### 4.6 連携（Integrations）

#### 一覧

```
GET /api/integrations
```

6種類の連携が存在しない場合は自動作成して返します。

---

#### 接続

```
POST /api/integrations/:id/connect
```

**リクエストボディ:**
```json
{
  "config": {
    "access_token": "xoxb-...",
    "workspace_id": "T..."
  }
}
```

---

#### 切断

```
DELETE /api/integrations/:id
```

---

#### 同期

```
POST /api/integrations/:id/sync
```

同期トリガー後、Webhookに通知します。

---

### 4.7 商談（Deals）

#### 一覧

```
GET /api/deals?stage=qualify
```

**クエリパラメータ:**
- `stage` (任意): prospect / qualify / demo / proposal / negotiation / closed_won / closed_lost

---

#### 詳細

```
GET /api/deals/:id
```

**レスポンス:** 商談 + 関連プレイブック一覧

---

#### 作成

```
POST /api/deals
```

**リクエストボディ:**
```json
{
  "company_id": "uuid",
  "contact_id": "uuid",
  "title": "エンタープライズプラン契約",
  "stage": "qualify",
  "amount": 1200000,
  "probability": 40,
  "owner": "田中太郎",
  "close_date": "2026-06-30"
}
```

---

#### 更新

```
PATCH /api/deals/:id
```

---

#### 削除

```
DELETE /api/deals/:id
```

---

### 4.8 ダッシュボード

#### KPI概要

```
GET /api/dashboard/overview
```

**レスポンス:**
```json
{
  "active_playbooks": 5,
  "today_chat_sessions": 12,
  "analyzed_communications": 48,
  "agent_reports_today": 7,
  "pipeline_value": 15000000,
  "active_deals": 23,
  "integrations_connected": 4
}
```

---

#### AIエージェント活動

```
GET /api/dashboard/agent_activity
```

**レスポンス:** 最新10件のAgentReport（企業名・コンタクト名付き）

---

#### パイプライン

```
GET /api/dashboard/pipeline
```

**レスポンス:**
```json
{
  "pipeline_by_stage": [
    {
      "stage": "qualify",
      "count": 5,
      "total_amount": 3000000,
      "avg_probability": 45
    }
  ],
  "active_playbooks": [ ... ]
}
```

---

## 5. バックエンドサービス

### 5.1 AiAnalysisService

**ファイル:** `rails_backend/app/services/ai_analysis_service.rb`

通信内容をClaude APIで分析するサービスです。

**メソッド:**

| メソッド | 引数 | 説明 |
|---------|------|------|
| `analyze_communication` | `content:`, `channel:` | 通信内容を分析 |
| `analyze_intent` | `messages:` | チャット履歴からインテントスコアを算出 |

**analyze_communication の出力:**
```json
{
  "summary": "200文字以内のサマリー",
  "sentiment": "positive",
  "keywords": ["料金", "デモ"],
  "action_items": ["デモ日程を調整する"],
  "intent_signals": "購買意向あり"
}
```

**使用モデル:** `claude-sonnet-4-6`（コンテキスト: 25,000トークン）

---

### 5.2 ChatbotService

**ファイル:** `rails_backend/app/services/chatbot_service.rb`

サイト埋め込みチャットbotの応答生成サービスです。

**動作フロー:**
1. システムプロンプト + セッション内メッセージ履歴をClaudeに渡す
2. Claudeが返答を生成
3. セッションのmessages配列を更新
4. 3往復ごとにAiAnalysisServiceでインテントスコアを再計算
5. インテント≥70の場合:
   - PlaybookGeneratorServiceを呼び出してプレイブック自動生成
   - WebhookNotifierServiceで外部通知

---

### 5.3 PlaybookGeneratorService

**ファイル:** `rails_backend/app/services/playbook_generator_service.rb`

Claude APIを使ってプレイブックを自動生成するサービスです。

**生成方法:**

| メソッド | 用途 |
|---------|------|
| `generate_from_chat_session(session)` | チャット履歴からプレイブック生成 |
| `generate_from_communications(company:, contact:)` | 通信データ（最新10件）からプレイブック生成 |

**生成される情報:**
- `title` — プレイブック名
- `objective` — 目的・ゴール
- `situation_summary` — 状況サマリー（AI+人間共有）
- `steps` — アクションステップ配列（上記action_type参照）

---

### 5.4 WebhookNotifierService

**ファイル:** `rails_backend/app/services/webhook_notifier_service.rb`

外部システム（AIエージェント等）にイベントを通知するサービスです。

**使用方法:**
```ruby
WebhookNotifierService.notify(
  event: "playbook_triggered",
  payload: { playbook_id: "uuid", ... }
)
```

**送信フォーマット:**
```json
{
  "event": "イベント名",
  "data": { ... },
  "timestamp": "2026-03-17T10:00:00Z"
}
```

**設定:** `AGENT_WEBHOOK_URL` 環境変数で送信先URLを指定。タイムアウト: 5秒。

**通知タイミング:**
- AgentReport作成時
- Integration同期時
- プレイブック自動生成時（チャットbotインテント≥70）
- 通信データ作成時

---

## 6. フロントエンド構成

### 6.1 ルーティング

| パス | ページコンポーネント | 説明 |
|-----|---------|------|
| `/` | Dashboard | ダッシュボード（KPI・活動サマリー） |
| `/chatbot` | Chatbot | チャットセッション一覧 |
| `/chatbot/:id` | ChatbotDetail | セッション詳細・チャット表示 |
| `/playbooks` | Playbooks | プレイブック一覧 |
| `/playbooks/:id` | PlaybookDetail | プレイブック詳細・ステップ実行 |
| `/communications` | Communications | 通信データ一覧・連携管理 |
| `/deals` | Deals | 商談パイプライン一覧 |
| `/deals/:id` | DealDetail | 商談詳細・連携プレイブック |
| `/analytics` | Analytics | パイプライン分析・KPIグラフ |

---

### 6.2 ページ機能

#### Dashboard（ダッシュボード）

- **KPIカード**: アクティブプレイブック数、当日チャット数、分析済み通信数、AIレポート数
- **エージェント活動フィード**: 最新5件のAgentReport
- **アクティブプレイブック**: 進捗バー付き一覧
- **連携ステータスサイドバー**: 6連携の接続状態
- **高インテントセッション**: インテントスコアが高いチャットセッション

#### Chatbot（チャットbot）

- セッション一覧（インテントバッジ、ステータス、メッセージ数）
- クリックでSessionDetailへ遷移

#### ChatbotDetail（チャットbot詳細）

- チャットバブル形式でメッセージ表示
- インテントスコアのリアルタイム表示
- セッション情報・企業情報サイドバー

#### Playbooks（プレイブック一覧）

- ステータスフィルタ（active / paused / completed）
- カード形式で進捗バー表示
- AI生成バッジ

#### PlaybookDetail（プレイブック詳細）

- ヘッダー: ステータスバッジ、「次のステップを実行」ボタン
- AI+人間共有の状況サマリーパネル
- ステップリスト（現在ステップをハイライト）
- サイドバー: 目的、コンタクト情報、実行ログ

#### Communications（通信データ）

- 連携管理グリッド（接続/切断ボタン）
- チャネルフィルタ（タブ形式）
- 通信カード（チャネルバッジ、センチメントバッジ、キーワード）

#### Deals（商談）

- インラインフォームで商談作成
- 検索 + ステージフィルタ
- テーブル形式で一覧表示

#### DealDetail（商談詳細）

- 商談情報（金額、成約確率バー）
- 関連プレイブック一覧
- コンタクト・企業情報サイドバー

#### Analytics（分析）

- KPIカード: パイプライン総額、勝率、アクティブプレイブック数、分析済み通信数
- パイプラインステージ別棒グラフ（金額・件数）
- アクティブプレイブック進捗テーブル

---

### 6.3 共通コンポーネント

| コンポーネント | 用途 | プロパティ |
|--------------|------|---------|
| `StatCard` | KPI表示カード | `label, value, sub, icon, color` |
| `IntentBadge` | インテントスコア表示 | `score` → hot/warm/cool/cold バッジ |
| `ChannelBadge` | 通信チャネルバッジ | `channel` (7種類対応) |
| `StageBadge` | 商談ステージバッジ | `stage` (7種類対応) |
| `PlaybookStepItem` | プレイブックステップ表示 | ステータスアイコン、アクションタイプ、チャネル |
| `LoadingSpinner` | ローディング表示 | — |

---

### 6.4 APIフック（useApi）

**ファイル:** `frontend/src/hooks/useApi.js`

```javascript
// データフェッチフック
const { data, loading, error, refetch } = useApi('/dashboard/overview');

// 直接API呼び出し
await api.post('/chatbot/sessions/:id/message', { message: '...' });
await api.patch('/playbooks/:id', { status: 'completed' });
```

**設定:**
- ベースURL: `VITE_API_BASE_URL` 環境変数 or `http://localhost:8000/api`
- Content-Type: `application/json`

---

## 7. 主要ワークフロー

### 7.1 チャットbot → プレイブック自動生成

```
1. ユーザーがチャットbotにメッセージ送信
   POST /api/chatbot/sessions/:id/message

2. ChatbotService が Claude に返答生成を依頼
   → セッションの messages 配列を更新

3. 3往復ごとにインテントスコアを再計算
   AiAnalysisService#analyze_intent

4. インテントスコア ≥ 70 の場合:
   a. PlaybookGeneratorService#generate_from_chat_session 呼び出し
   b. Playbook レコード作成（status: "active"）
   c. WebhookNotifierService で外部通知
      → event: "playbook_triggered"

5. フロントエンドがインテントスコアを表示
   → ダッシュボードの「高インテントセッション」に表示
```

---

### 7.2 AIエージェント → プレイブック実行

```
1. AIエージェントが会社コンテキストを取得
   POST /api/agent/request_context { company_id }

2. AIエージェントが活動を報告
   POST /api/agent/report { action_taken, insights }
   → WebhookNotifierService 通知

3. AIエージェントがプレイブックを取得
   GET /api/agent/playbook/:id

4. ステップ完了を報告
   PATCH /api/agent/playbook/:id/step/:n { status: "completed", result: "..." }
   → PlaybookExecution 作成
   → playbook.current_step を更新

5. 全ステップ完了で playbook.status = "completed"
```

---

### 7.3 通信データ自動分析

```
1. AIエージェントまたは外部からデータを登録
   POST /api/communications { content, channel, company_id }

2. content がある場合 AiAnalysisService#analyze_communication を自動呼び出し
   → summary, sentiment, keywords, action_items を付加
   → analyzed_at を記録

3. WebhookNotifierService で通知
   → event: "communication_created"

4. フロントエンドの Communications ページで閲覧可能
```

---

### 7.4 人間によるプレイブックステップ実行

```
1. 人間がダッシュボードでプレイブックを確認
   GET /api/playbooks/:id

2. 「次のステップを実行」ボタンをクリック
   POST /api/playbooks/:id/execute

3. 現在の pending ステップが実行済みになる
   → PlaybookExecution 作成（executed_by: ユーザー名）
   → playbook.current_step がインクリメント

4. PlaybookDetail 画面でリアルタイムに進捗確認
```

---

## 8. 環境変数・設定

### バックエンド（`rails_backend/.env`）

| 変数名 | 必須 | 説明 |
|-------|------|------|
| `DATABASE_URL` | ✅ | PostgreSQL接続URL（Supabase） |
| `ANTHROPIC_API_KEY` | ✅ | Claude API キー（`sk-ant-...`） |
| `OPENAI_API_KEY` | — | OpenAI Whisper用（今後使用） |
| `AGENT_API_KEY` | ✅ | AIエージェント認証キー |
| `AGENT_WEBHOOK_URL` | ✅ | Webhook送信先URL |

### フロントエンド（`frontend/.env`）

| 変数名 | 必須 | 説明 |
|-------|------|------|
| `VITE_API_BASE_URL` | — | APIベースURL（本番環境） |

### CORS設定

`config/initializers/cors.rb` で全オリジンを許可（開発環境）。本番環境では適切に制限してください。

---

## 補足情報

### セキュリティ

- AIエージェント専用APIは `X-Agent-Api-Key` ヘッダーで認証
- APIキー等は `.env` ファイルで管理（`.gitignore` 対象）
- `bundler-audit` / `brakeman` による脆弱性チェックを実施

### スケーラビリティ

- `solid_queue` によるジョブキュー（同期処理の非同期化に利用可能）
- `solid_cache` によるキャッシュ
- 全テーブルUUID主キーで分散DBに対応

### 今後の拡張候補

- OpenAI Whisper による録音の文字起こし自動化
- 商談ステージ変更時の自動プレイブック更新
- Salesforce / HubSpot との双方向CRM同期
