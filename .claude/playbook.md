# プレイブック仕様書

## 概要

プレイブックは「AIエージェント・営業担当者・顧客」の3者が連携して受注に向けたアクションを実行するためのタスクリストです。
AIがチャットセッションや通信ログから自動生成し、各ステップをAI・人間・顧客のいずれかが実行します。

---

## ユーザーストーリー

### 営業担当者（人間）

**US-1: プレイブックの状況を把握したい**
> 営業担当者として、AIが動いている間も今どのステップまで進んでいるか・次に何をすべきかをダッシュボードで一目で確認したい。
> なぜなら、自分が介入すべきタイミングを見逃したくないから。

- `GET /api/playbooks/:id/status` の `status_summary` を画面に表示
- 進捗バー・現在ステップ・次アクションが見える

---

**US-2: 自分が担当するステップを手動実行したい**
> 営業担当者として、`executor_type: human` のステップ（提案書レビュー・商談など）を完了したらプレイブックにその結果を記録したい。
> なぜなら、AIが次のステップに進む前に自分の完了を伝える必要があるから。

- `POST /api/playbooks/:id/execute` で `step_index` と `result` を送信
- 実行後、次の pending ステップへ自動的に `current_step` が移動

---

**US-3: AIのステップをスキップしたい**
> 営業担当者として、状況が変わって不要になったステップをスキップしてプレイブックを先に進めたい。
> なぜなら、硬直したフローより柔軟な対応が受注率を上げるから。

- `POST /api/playbooks/:id/execute` に `skip: true` を送信
- ステップが `skipped` になり次の pending へ進む

---

**US-4: プレイブックを一時停止・再開したい**
> 営業担当者として、顧客都合で商談が止まっているときにAIの自動実行を一時停止し、再開できるようにしたい。
> なぜなら、タイミングを外した連絡は顧客体験を損なうから。

- `PATCH /api/playbooks/:id` で `status: paused` / `active` を切り替え

---

### AIエージェント

**US-5: 通信ログからプレイブックを自動生成したい**
> AIエージェントとして、Slack・Zoom・メールなどの通信ログを分析したうえで、受注に向けた最適なアクションプランを自動生成したい。
> なぜなら、営業担当者が毎回手動でプランを立てる手間を省きたいから。

- `POST /api/agent/trigger_playbook` に `company_id` を送信
- `PlaybookGeneratorService` が Claude API で steps を生成してレコード作成

---

**US-6: 自分が担当するステップを実行完了として報告したい**
> AIエージェントとして、メール送信・Slack通知・CRM更新などのアクションを実行した後、その結果をプレイブックに記録して次のステップへ進めたい。
> なぜなら、人間に状況を見えるようにしながら自律的にフローを進めるため。

- `PATCH /api/agent/playbook/:id/step/:step_index` に `status: completed` と `result` を送信
- `PlaybookExecution` に実行ログが記録され、`maybe_auto_complete!` が走る

---

**US-7: 現在のプレイブック状況を確認してから次のアクションを決めたい**
> AIエージェントとして、実行前に `status_summary` を取得して現状と次アクションを把握したい。
> なぜなら、文脈を理解した上で適切な行動を選択するため。

- `GET /api/agent/playbook/:id` で `status_summary.next_action` を確認
- `executor_type` が `ai` のステップのみ自律実行し、`human` / `customer` は待機

---

### 顧客

**US-8: チャットbotで返信するだけで商談を前に進めたい**
> 顧客として、営業からの確認事項にチャットbotで返信するだけで、次のステップへ自動的に進んでほしい。
> なぜなら、メール返信などの手間を省いてシームレスに商談を進めたいから。

- `executor_type: customer` / `action_type: wait_customer_response` のステップが pending 状態で待機
- 顧客がチャットbotに返信すると該当ステップが自動 `completed` になり次へ進む

---

## データモデル

### Playbook

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | プレイブックID |
| `company_id` | uuid | 対象企業 |
| `contact_id` | uuid | 対象担当者 |
| `title` | string | プレイブックタイトル |
| `status` | string | `active` / `paused` / `completed` |
| `steps` | jsonb | ステップ一覧（後述） |
| `current_step` | integer | 現在の実行ステップindex |
| `created_by` | string | 作成者（通常 `ai_agent`） |
| `objective` | text | このプレイブックの目標 |
| `situation_summary` | text | 現状サマリー（AIと人間が共有するコンテキスト） |

### PlaybookExecution

ステップが実行されるたびに記録する実行ログ。

| カラム | 型 | 説明 |
|---|---|---|
| `playbook_id` | uuid | 対象プレイブック |
| `step_index` | integer | 実行したステップのindex |
| `status` | string | `pending` / `in_progress` / `completed` / `failed` / `skipped` |
| `result` | text | 実行結果のテキスト |
| `executed_by` | string | 実行者（`ai_agent` または 人間のユーザー名） |
| `executed_at` | datetime | 実行日時 |

---

## stepsフィールド仕様

`steps` はJSONB配列。各要素の構造：

```json
{
  "step": 1,
  "action_type": "send_email",
  "executor_type": "ai",
  "channel": "email",
  "target": "yamada@example.com",
  "template": "提案資料送付のメール文面",
  "due_in_hours": 24,
  "status": "pending",
  "result": null,
  "completed_at": null,
  "executed_by": null
}
```

### action_type 一覧

| action_type | 説明 |
|---|---|
| `send_slack_message` | Slackメッセージ送信 |
| `schedule_meeting` | ミーティング設定 |
| `send_email` | メール送信 |
| `update_crm` | CRM情報更新（Salesforce/HubSpot） |
| `create_followup_task` | フォローアップタスク作成 |
| `send_proposal` | 提案資料送付 |
| `request_demo` | デモ依頼 |
| `share_case_study` | 事例共有 |
| `follow_up_call` | フォローアップ通話 |
| `wait_customer_response` | 顧客の返答待ち |

### executor_type（実行者種別）

| executor_type | 実行者 | 説明 |
|---|---|---|
| `ai` | AIエージェント | メール・Slack送信・CRM更新など自律実行できるアクション |
| `human` | 営業担当者 | 判断が必要な会議・提案内容の最終確認など |
| `customer` | 顧客 | チャットbotや返信を通じて顧客が完了させるアクション |

### step status の遷移

```
pending → in_progress → completed
                      → failed
                      → skipped
```

- `wait_customer_response` ステップは顧客がチャットbotで返信した時点で自動 `completed`
- 全ステップが `completed` / `skipped` / `failed` になると Playbook の `status` が自動で `completed` に遷移

---

## 生成フロー

```
チャットセッション終了 or 通信ログ蓄積
    ↓
PlaybookGeneratorService#generate
    ↓
Claude API (claude-sonnet-4-6) にプロンプト送信
    ↓
JSON形式でtitle / objective / situation_summary / steps を取得
    ↓
Playbook レコード作成（status: active, created_by: ai_agent）
```

生成トリガーは2パターン：
- `generate_from_chat_session(session)` — チャットセッションのメッセージ履歴から生成
- `generate_from_communications(company:, contact:)` — 直近10件の通信ログから生成

---

## API

### 人間向けAPI（ダッシュボード）

| メソッド | パス | 説明 |
|---|---|---|
| `GET` | `/api/playbooks` | 一覧取得（`?status=active` でフィルタ可） |
| `GET` | `/api/playbooks/:id` | 詳細取得（実行ログ含む） |
| `GET` | `/api/playbooks/:id/status` | AIと人間の共有ステータスビュー |
| `POST` | `/api/playbooks` | 手動作成 |
| `PATCH` | `/api/playbooks/:id` | 更新 |
| `POST` | `/api/playbooks/:id/execute` | ステップを手動実行またはスキップ |

#### POST /api/playbooks/:id/execute パラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `step_index` | integer | 実行するステップindex（省略時は次のpendingステップ） |
| `skip` | boolean | `true` でスキップ扱い |
| `result` | string | 実行結果テキスト |

### AIエージェント向けAPI（要 `X-Agent-Api-Key` ヘッダー）

| メソッド | パス | 説明 |
|---|---|---|
| `POST` | `/api/agent/trigger_playbook` | 通信ログからプレイブック自動生成 |
| `GET` | `/api/agent/playbook/:id` | プレイブック取得（`status_summary` 含む） |
| `PATCH` | `/api/agent/playbook/:id/step/:step_index` | ステップ完了報告 |

#### PATCH step パラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `status` | string | `completed` / `failed` / `skipped` |
| `result` | string | 実行結果テキスト |

---

## status_summary（AIと人間の共有コンテキスト）

`Playbook#status_summary` はAIと人間が共通認識を持つためのビューオブジェクトです。

```json
{
  "situation": "現状サマリーテキスト",
  "progress": "2/5ステップ完了",
  "current_step": 2,
  "next_action": {
    "step": 3,
    "action_type": "send_email",
    "executor_type": "human",
    "channel": "email",
    "description": "提案書を送付する"
  },
  "status": "active"
}
```

AIエージェントは `GET /api/agent/playbook/:id` でこの情報を取得し、次に何をすべきか判断します。
人間はダッシュボードの「プレイブック詳細」画面で同じ情報を確認します。

---

## Playbook status の遷移

```
active ──→ paused   （一時停止）
       ──→ completed （全ステップ終了 or 手動完了）
paused ──→ active   （再開）
```

`maybe_auto_complete!` メソッドが全ステップ終了時に自動で `completed` へ遷移させます。
