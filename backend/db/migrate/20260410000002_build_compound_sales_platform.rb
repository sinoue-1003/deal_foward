class BuildCompoundSalesPlatform < ActiveRecord::Migration[8.1]
  # 新規テーブル一覧（RLS適用対象）
  NEW_TENANT_TABLES = %w[
    leads
    products
    quotes
    quote_line_items
    contracts
    sequences
    sequence_steps
    sequence_enrollments
    meetings
    meeting_attendees
    meeting_insights
    deal_stage_histories
    forecast_periods
    forecasts
    territories
    territory_assignments
    quotas
    notes
    activity_timeline
    email_messages
    customer_health_scores
    chat_messages
    audit_logs
  ].freeze

  def up
    # ================================================================
    # 既存テーブルの修正
    # ================================================================

    # companies: 企業階層・アカウントタイプ・担当営業を追加
    add_column    :companies, :parent_company_id, :uuid, null: true
    add_column    :companies, :account_type,      :string, default: "prospect"
    # prospect / customer / at_risk / churned / partner
    add_column    :companies, :owner_id,          :uuid, null: true
    add_foreign_key :companies, :companies, column: :parent_company_id
    add_foreign_key :companies, :users,     column: :owner_id
    add_index :companies, :parent_company_id
    add_index :companies, :owner_id
    add_index :companies, :account_type

    # contacts: ステータス・リードスコア・担当営業を追加
    add_column    :contacts, :status,     :string, default: "active"   # active/inactive/unsubscribed/bounced
    add_column    :contacts, :lead_score, :integer, default: 0
    add_column    :contacts, :owner_id,   :uuid, null: true
    add_foreign_key :contacts, :users, column: :owner_id
    add_index :contacts, :owner_id
    add_index :contacts, :status
    add_index :contacts, :lead_score

    # deals: owner(string) → owner_id(uuid FK) へ移行
    add_column    :deals, :owner_id, :uuid, null: true
    add_foreign_key :deals, :users, column: :owner_id
    add_index :deals, :owner_id
    remove_column :deals, :owner  # 旧string列を削除

    # ================================================================
    # 1. leads — インバウンド/アウトバウンド リード管理
    #    （コンタクト化・商談化前の段階を管理）
    # ================================================================
    create_table :leads, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.string  :first_name,   null: false
      t.string  :last_name,    null: false
      t.string  :email
      t.string  :phone
      t.string  :company_name
      t.string  :job_title
      t.string  :source       # inbound_form/chat/referral/cold_outreach/event/partner/web/other
      t.string  :status, null: false, default: "new"  # new/working/converted/disqualified
      t.integer :score,  default: 0
      t.references :assigned_to, type: :uuid, null: true,
                   foreign_key: { to_table: :users }
      t.references :converted_to_contact, type: :uuid, null: true,
                   foreign_key: { to_table: :contacts }
      t.references :converted_to_deal, type: :uuid, null: true,
                   foreign_key: { to_table: :deals }
      t.datetime :converted_at
      t.string   :disqualified_reason
      t.jsonb    :utm_params,    default: {}, null: false
      t.jsonb    :custom_fields, default: {}, null: false
      t.timestamps
    end
    add_index :leads, :status
    add_index :leads, :score
    add_index :leads, :source
    add_index :leads, :tenant_id

    # ================================================================
    # 2. products — 製品・サービスカタログ
    # ================================================================
    create_table :products, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.string  :name,           null: false
      t.string  :code                                  # SKU / 製品コード
      t.string  :category
      t.string  :product_type,   default: "recurring"  # one_time/recurring/usage_based
      t.decimal :default_price,  precision: 15, scale: 2
      t.string  :currency,       default: "JPY"
      t.string  :billing_period, default: "annual"     # monthly/annual/one_time/multi_year
      t.text    :description
      t.boolean :is_active,      default: true, null: false
      t.jsonb   :metadata,       default: {}, null: false
      t.timestamps
    end
    add_index :products, :is_active
    add_index :products, :category
    add_index :products, :product_type
    add_index :products, :tenant_id

    # ================================================================
    # 3. quotes — 見積書
    # ================================================================
    create_table :quotes, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :deal,    type: :uuid, null: true,  foreign_key: true
      t.references :contact, type: :uuid, null: true,  foreign_key: true
      t.string   :quote_number, null: false
      t.string   :status, null: false, default: "draft"
      # draft/sent/viewed/accepted/rejected/expired
      t.date     :valid_until
      t.decimal  :subtotal,        precision: 15, scale: 2, default: 0
      t.decimal  :discount_amount, precision: 15, scale: 2, default: 0
      t.decimal  :tax_amount,      precision: 15, scale: 2, default: 0
      t.decimal  :total_amount,    precision: 15, scale: 2, default: 0
      t.string   :currency, default: "JPY"
      t.text     :notes
      t.text     :terms
      t.references :created_by, type: :uuid, null: true,
                   foreign_key: { to_table: :users }
      t.references :approved_by, type: :uuid, null: true,
                   foreign_key: { to_table: :users }
      t.datetime :sent_at
      t.datetime :viewed_at
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.datetime :expired_at
      t.timestamps
    end
    add_index :quotes, :status
    add_index :quotes, :quote_number
    add_index :quotes, :tenant_id

    # ================================================================
    # 4. quote_line_items — 見積明細
    # ================================================================
    create_table :quote_line_items, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :quote,   type: :uuid, null: false, foreign_key: true
      t.references :product, type: :uuid, null: true,  foreign_key: true
      t.string   :name,         null: false      # 製品名（非正規化）
      t.integer  :quantity,     null: false, default: 1
      t.decimal  :unit_price,   null: false, precision: 15, scale: 2
      t.decimal  :discount_pct, precision: 5, scale: 2, default: 0
      t.decimal  :total_price,  null: false, precision: 15, scale: 2
      t.text     :description
      t.integer  :sort_order, default: 0
      t.timestamps
    end
    add_index :quote_line_items, :tenant_id

    # ================================================================
    # 5. contracts — 契約管理
    # ================================================================
    create_table :contracts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :deal,    type: :uuid, null: true,  foreign_key: true
      t.references :company, type: :uuid, null: true,  foreign_key: true
      t.references :contact, type: :uuid, null: true,  foreign_key: true
      t.references :quote,   type: :uuid, null: true,  foreign_key: true
      t.references :owner,   type: :uuid, null: true,
                   foreign_key: { to_table: :users }
      t.string   :contract_number, null: false
      t.string   :status, null: false, default: "draft"
      # draft/active/expired/terminated/renewed
      t.string   :contract_type, default: "new"
      # new/renewal/expansion/amendment
      t.date     :start_date
      t.date     :end_date
      t.date     :renewal_date
      t.boolean  :auto_renew, default: false, null: false
      t.decimal  :value,          precision: 15, scale: 2
      t.decimal  :arr,            precision: 15, scale: 2  # 年間経常収益
      t.decimal  :mrr,            precision: 15, scale: 2  # 月次経常収益
      t.string   :currency, default: "JPY"
      t.string   :billing_period, default: "annual"
      # monthly/annual/one_time/multi_year
      t.text     :terms
      t.string   :terms_url
      t.string   :signed_by
      t.datetime :signed_at
      t.datetime :terminated_at
      t.string   :termination_reason
      t.timestamps
    end
    add_index :contracts, :status
    add_index :contracts, :contract_number
    add_index :contracts, :renewal_date
    add_index :contracts, :contract_type
    add_index :contracts, :tenant_id

    # ================================================================
    # 6. sequences — セールスエンゲージメント シーケンス（カデンス）
    # ================================================================
    create_table :sequences, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.string  :name,          null: false
      t.text    :description
      t.string  :status, null: false, default: "active"
      # active/paused/archived
      t.string  :sequence_type, default: "outbound"
      # outbound/inbound/nurture/onboarding/renewal
      t.string  :target_stage   # 対象の商談ステージ
      t.references :created_by, type: :uuid, null: true,
                   foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :sequences, :status
    add_index :sequences, :sequence_type
    add_index :sequences, :tenant_id

    # ================================================================
    # 7. sequence_steps — シーケンスのステップ
    # ================================================================
    create_table :sequence_steps, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,   type: :uuid, null: false, foreign_key: true
      t.references :sequence, type: :uuid, null: false, foreign_key: true
      t.integer :step_index, null: false
      t.string  :action_type, null: false
      # email/call/linkedin_message/sms/task/wait
      t.integer :day_offset, null: false, default: 0  # 登録からN日後
      t.string  :subject
      t.text    :template
      t.boolean :auto_execute, default: true, null: false  # AIが自動実行するか
      t.timestamps
    end
    add_index :sequence_steps, [ :sequence_id, :step_index ], unique: true
    add_index :sequence_steps, :tenant_id

    # ================================================================
    # 8. sequence_enrollments — シーケンスへの連絡先登録
    # ================================================================
    create_table :sequence_enrollments, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,   type: :uuid, null: false, foreign_key: true
      t.references :sequence, type: :uuid, null: false, foreign_key: true
      t.references :contact,  type: :uuid, null: false, foreign_key: true
      t.references :deal,     type: :uuid, null: true,  foreign_key: true
      t.string  :status, null: false, default: "active"
      # active/paused/completed/replied/opted_out/bounced
      t.integer :current_step_index, default: 0
      t.datetime :enrolled_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :completed_at
      t.datetime :paused_at
      t.references :enrolled_by, type: :uuid, null: true,
                   foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :sequence_enrollments, :status
    add_index :sequence_enrollments, [ :sequence_id, :contact_id ]
    add_index :sequence_enrollments, :tenant_id

    # ================================================================
    # 9. meetings — 商談ミーティング
    # ================================================================
    create_table :meetings, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :deal,    type: :uuid, null: true,  foreign_key: true
      t.references :company, type: :uuid, null: true,  foreign_key: true
      t.string   :title, null: false
      t.string   :meeting_type, default: "other"
      # discovery/demo/proposal/negotiation/kickoff/qbr/other
      t.string   :status, null: false, default: "scheduled"
      # scheduled/in_progress/completed/cancelled/no_show
      t.datetime :started_at
      t.datetime :ended_at
      t.integer  :duration_minutes
      t.string   :meeting_url
      t.string   :recording_url
      t.string   :external_id          # カレンダーイベントID
      t.timestamps
    end
    add_index :meetings, :status
    add_index :meetings, :meeting_type
    add_index :meetings, :started_at
    add_index :meetings, :tenant_id

    # ================================================================
    # 10. meeting_attendees — ミーティング参加者
    # ================================================================
    create_table :meeting_attendees, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :meeting, type: :uuid, null: false, foreign_key: true
      t.references :contact, type: :uuid, null: true,  foreign_key: true
      t.references :user,    type: :uuid, null: true,  foreign_key: true
      t.string  :name           # 非正規化（contactレコードなし外部参加者用）
      t.string  :email
      t.string  :attendee_type, default: "external"  # internal/external
      t.boolean :attended, default: false, null: false
      t.timestamps
    end
    add_index :meeting_attendees, :tenant_id

    # ================================================================
    # 11. meeting_insights — AI抽出ミーティングインサイト
    #     （録音・文字起こし・AI分析結果）
    # ================================================================
    create_table :meeting_insights, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :meeting, type: :uuid, null: false, foreign_key: true,
                   index: { unique: true }
      t.text     :transcript                                 # 全文テキスト
      t.text     :summary                                    # AIサマリー
      t.jsonb    :key_topics,      default: [], null: false  # 主要トピック
      t.jsonb    :action_items,    default: [], null: false  # アクションアイテム
      t.jsonb    :pain_points,     default: [], null: false  # 課題・ペイン
      t.jsonb    :objections,      default: [], null: false  # 反論・懸念
      t.jsonb    :next_steps,      default: [], null: false  # 次のステップ
      t.jsonb    :risk_flags,      default: [], null: false  # リスクフラグ
      t.integer  :sentiment_score                            # -100 to 100
      t.integer  :engagement_score                           # 0-100
      t.integer  :talk_ratio_rep                             # 担当者の発言割合 0-100
      t.datetime :analyzed_at
      t.timestamps
    end
    add_index :meeting_insights, :tenant_id

    # ================================================================
    # 12. deal_stage_histories — 商談ステージ変遷履歴
    # ================================================================
    create_table :deal_stage_histories, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.references :deal,   type: :uuid, null: false, foreign_key: true
      t.references :changed_by, type: :uuid, null: true,
                   foreign_key: { to_table: :users }
      t.string   :from_stage                              # nilは初期作成時
      t.string   :to_stage,          null: false
      t.integer  :days_in_from_stage                      # 前ステージの滞留日数
      t.text     :reason
      t.datetime :changed_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end
    add_index :deal_stage_histories, [ :deal_id, :changed_at ]
    add_index :deal_stage_histories, :tenant_id

    # ================================================================
    # 13. forecast_periods — フォーキャスト期間
    # ================================================================
    create_table :forecast_periods, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.string  :period_type, null: false, default: "quarterly"  # monthly/quarterly
      t.date    :start_date,  null: false
      t.date    :end_date,    null: false
      t.integer :fiscal_year, null: false
      t.integer :fiscal_quarter
      t.integer :fiscal_month
      t.boolean :is_current, default: false, null: false
      t.timestamps
    end
    add_index :forecast_periods, [ :tenant_id, :start_date ]
    add_index :forecast_periods, :is_current
    add_index :forecast_periods, :tenant_id

    # ================================================================
    # 14. forecasts — 営業フォーキャスト提出
    # ================================================================
    create_table :forecasts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,          type: :uuid, null: false, foreign_key: true
      t.references :forecast_period, type: :uuid, null: false, foreign_key: true
      t.references :user,            type: :uuid, null: false, foreign_key: true
      t.references :submitted_for,   type: :uuid, null: true,  # マネージャーロールアップ用
                   foreign_key: { to_table: :users }
      t.decimal  :commit_amount,    precision: 15, scale: 2, default: 0
      t.decimal  :best_case_amount, precision: 15, scale: 2, default: 0
      t.decimal  :pipeline_amount,  precision: 15, scale: 2, default: 0
      t.decimal  :closed_amount,    precision: 15, scale: 2, default: 0
      t.string   :currency, default: "JPY"
      t.text     :notes
      t.datetime :submitted_at
      t.timestamps
    end
    add_index :forecasts, [ :forecast_period_id, :user_id ]
    add_index :forecasts, :tenant_id

    # ================================================================
    # 15. territories — 営業テリトリー（地域・業界・規模別担当区分）
    # ================================================================
    create_table :territories, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.string  :name,           null: false
      t.text    :description
      t.string  :territory_type, default: "geographic"
      # geographic/vertical/account_size/product
      t.references :parent_territory, type: :uuid, null: true,
                   foreign_key: { to_table: :territories }
      t.references :owner, type: :uuid, null: true,
                   foreign_key: { to_table: :users }
      t.jsonb   :criteria, default: {}, null: false  # 自動割り当てルール
      t.timestamps
    end
    add_index :territories, :territory_type
    add_index :territories, :tenant_id

    # ================================================================
    # 16. territory_assignments — 企業とテリトリーの紐付け
    # ================================================================
    create_table :territory_assignments, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,    type: :uuid, null: false, foreign_key: true
      t.references :territory, type: :uuid, null: false, foreign_key: true
      t.references :company,   type: :uuid, null: false, foreign_key: true
      t.references :user,      type: :uuid, null: true,  foreign_key: true
      t.datetime :assigned_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end
    add_index :territory_assignments, [ :territory_id, :company_id ], unique: true
    add_index :territory_assignments, :tenant_id

    # ================================================================
    # 17. quotas — 営業クォータ（目標）
    # ================================================================
    create_table :quotas, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,          type: :uuid, null: false, foreign_key: true
      t.references :user,            type: :uuid, null: false, foreign_key: true
      t.references :forecast_period, type: :uuid, null: false, foreign_key: true
      t.string   :quota_type, default: "revenue"
      # revenue/deal_count/activity_count/new_logo
      t.decimal  :target_amount, precision: 15, scale: 2
      t.string   :currency, default: "JPY"
      t.timestamps
    end
    add_index :quotas, [ :user_id, :forecast_period_id ], unique: true
    add_index :quotas, :tenant_id

    # ================================================================
    # 18. notes — 多態的メモ（企業・連絡先・商談・リードに紐付く）
    # ================================================================
    create_table :notes, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.string   :notable_type, null: false  # Company/Contact/Deal/Lead/Playbook
      t.uuid     :notable_id,   null: false
      t.text     :content,      null: false
      t.boolean  :is_pinned, default: false, null: false
      t.references :created_by, type: :uuid, null: true,
                   foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :notes, [ :notable_type, :notable_id ]
    add_index :notes, :tenant_id

    # ================================================================
    # 19. activity_timeline — 統合アクティビティフィード
    #     （全チャネルの活動を1か所で参照するための非正規化テーブル）
    # ================================================================
    create_table :activity_timeline, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :company, type: :uuid, null: true,  foreign_key: true
      t.references :contact, type: :uuid, null: true,  foreign_key: true
      t.references :deal,    type: :uuid, null: true,  foreign_key: true
      t.string   :activity_type, null: false
      # email_sent/call_made/meeting_held/deal_stage_changed/note_added/
      # task_completed/sequence_enrolled/playbook_executed/lead_converted/
      # contract_signed/quote_sent/chat_converted
      t.string   :actor_type, null: false, default: "user"  # user/ai_agent
      t.uuid     :actor_id
      t.datetime :occurred_at, null: false
      t.string   :title
      t.text     :description
      t.jsonb    :metadata, default: {}, null: false  # source_type/source_id 等
      t.timestamps
    end
    add_index :activity_timeline, :activity_type
    add_index :activity_timeline, :occurred_at
    add_index :activity_timeline, [ :deal_id, :occurred_at ]
    add_index :activity_timeline, [ :contact_id, :occurred_at ]
    add_index :activity_timeline, :tenant_id

    # ================================================================
    # 20. email_messages — 個別メールトラッキング
    # ================================================================
    create_table :email_messages, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :contact, type: :uuid, null: true,  foreign_key: true
      t.references :deal,    type: :uuid, null: true,  foreign_key: true
      t.references :company, type: :uuid, null: true,  foreign_key: true
      t.references :sequence_enrollment, type: :uuid, null: true, foreign_key: true
      t.string   :direction, null: false, default: "outbound"  # inbound/outbound
      t.string   :subject
      t.text     :body_text
      t.text     :body_html
      t.string   :from_email
      t.jsonb    :to_emails, default: [], null: false
      t.jsonb    :cc_emails, default: [], null: false
      t.string   :status, default: "sent"
      # draft/sent/delivered/opened/clicked/replied/bounced/spam
      t.string   :thread_id     # メールスレッドID
      t.string   :external_id   # メールプロバイダーのID
      t.datetime :opened_at
      t.datetime :clicked_at
      t.datetime :replied_at
      t.datetime :bounced_at
      t.timestamps
    end
    add_index :email_messages, :status
    add_index :email_messages, :thread_id
    add_index :email_messages, :tenant_id

    # ================================================================
    # 21. customer_health_scores — カスタマーヘルススコア
    #     （CS・リニューアル管理）
    # ================================================================
    create_table :customer_health_scores, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,   type: :uuid, null: false, foreign_key: true
      t.references :company,  type: :uuid, null: false, foreign_key: true
      t.references :contract, type: :uuid, null: true,  foreign_key: true
      t.integer  :overall_score,    default: 0   # 0-100
      t.integer  :usage_score,      default: 0
      t.integer  :support_score,    default: 0
      t.integer  :engagement_score, default: 0
      t.integer  :nps_score                       # -100 to 100
      t.string   :churn_risk, default: "low"      # low/medium/high/critical
      t.jsonb    :factors, default: {}, null: false
      t.datetime :scored_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end
    add_index :customer_health_scores, :churn_risk
    add_index :customer_health_scores, :scored_at
    add_index :customer_health_scores, :tenant_id

    # ================================================================
    # 22. chat_messages — チャットセッションのメッセージ正規化
    #     （旧 chat_sessions.messages jsonb配列 → テーブルへ）
    # ================================================================
    create_table :chat_messages, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,       type: :uuid, null: false, foreign_key: true
      t.references :chat_session, type: :uuid, null: false, foreign_key: true
      t.string  :role,    null: false   # user/assistant/system
      t.text    :content, null: false
      t.string  :intent_detected
      t.jsonb   :entities, default: {}, null: false  # 検出エンティティ（名前・メール等）
      t.timestamps
    end
    add_index :chat_messages, [ :chat_session_id, :created_at ]
    add_index :chat_messages, :tenant_id

    # ================================================================
    # 23. audit_logs — 全操作の監査ログ（GDPR・セキュリティ対応）
    # ================================================================
    create_table :audit_logs, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.references :user,   type: :uuid, null: true,  foreign_key: true
      t.string   :entity_type,    null: false   # Company/Contact/Deal/etc.
      t.uuid     :entity_id,      null: false
      t.string   :action,         null: false   # create/update/delete/view
      t.jsonb    :changed_fields, default: {}, null: false  # before/after
      t.string   :ip_address
      t.string   :user_agent
      t.datetime :occurred_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end
    add_index :audit_logs, [ :entity_type, :entity_id ]
    add_index :audit_logs, :occurred_at
    add_index :audit_logs, :tenant_id

    # ================================================================
    # 全新規テーブルに RLS を適用
    # ================================================================
    NEW_TENANT_TABLES.each do |table|
      execute <<~SQL
        ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY;
        ALTER TABLE #{table} FORCE ROW LEVEL SECURITY;
        CREATE POLICY tenant_isolation ON #{table}
          USING (is_admin() OR tenant_id = current_tenant_id());
      SQL
    end
  end

  def down
    NEW_TENANT_TABLES.each do |table|
      execute "DROP POLICY IF EXISTS tenant_isolation ON #{table};"
      execute "ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY;"
    end

    # FK依存順に逆順でドロップ
    drop_table :audit_logs
    drop_table :chat_messages
    drop_table :customer_health_scores
    drop_table :email_messages
    drop_table :activity_timeline
    drop_table :notes
    drop_table :quotas
    drop_table :territory_assignments
    drop_table :territories
    drop_table :forecasts
    drop_table :forecast_periods
    drop_table :deal_stage_histories
    drop_table :meeting_insights
    drop_table :meeting_attendees
    drop_table :meetings
    drop_table :sequence_enrollments
    drop_table :sequence_steps
    drop_table :sequences
    drop_table :contracts
    drop_table :quote_line_items
    drop_table :quotes
    drop_table :products
    drop_table :leads

    # 既存テーブルの修正を元に戻す
    remove_foreign_key :deals, column: :owner_id
    remove_index :deals, :owner_id
    remove_column :deals, :owner_id
    add_column :deals, :owner, :string  # 旧string列を復元

    remove_foreign_key :contacts, column: :owner_id
    remove_index :contacts, :owner_id
    remove_index :contacts, :status
    remove_index :contacts, :lead_score
    remove_column :contacts, :owner_id
    remove_column :contacts, :lead_score
    remove_column :contacts, :status

    remove_foreign_key :companies, column: :owner_id
    remove_foreign_key :companies, column: :parent_company_id
    remove_index :companies, :account_type
    remove_index :companies, :owner_id
    remove_index :companies, :parent_company_id
    remove_column :companies, :owner_id
    remove_column :companies, :account_type
    remove_column :companies, :parent_company_id
  end
end
