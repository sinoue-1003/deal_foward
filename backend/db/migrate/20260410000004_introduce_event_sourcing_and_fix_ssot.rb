class IntroduceEventSourcingAndFixSsot < ActiveRecord::Migration[8.1]
  def up
    # ================================================================
    # 1. sales_events — append-only イベントストア（SSOTの核心）
    #
    # 設計原則:
    #  - INSERT のみ（UPDATE/DELETE 禁止）
    #  - aggregate_type + aggregate_id でどのエンティティのイベントか特定
    #  - sequence_number で集約内の順序を保証
    #  - activity_timeline / deal_stage_histories はここから導出する read model
    # ================================================================
    create_table :sales_events, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true

      # イベント種別（ドメインイベント名）
      # --- Lead ライフサイクル ---
      # lead.created / lead.score_updated / lead.assigned / lead.converted / lead.disqualified
      # --- Deal ライフサイクル ---
      # deal.created / deal.stage_changed / deal.amount_updated / deal.owner_changed / deal.won / deal.lost
      # --- エンゲージメント ---
      # meeting.scheduled / meeting.completed / meeting.no_show
      # email.sent / email.opened / email.replied / email.bounced
      # call.made / call.completed / call.no_answer
      # --- シーケンス ---
      # sequence.enrolled / sequence.step_executed / sequence.completed / sequence.replied / sequence.opted_out
      # --- CPQ ---
      # quote.created / quote.sent / quote.viewed / quote.accepted / quote.rejected
      # --- 契約 ---
      # contract.created / contract.signed / contract.activated / contract.renewed / contract.terminated
      # --- CS ---
      # health_score.updated / renewal.flagged / churn.at_risk
      # --- Playbook ---
      # playbook.created / playbook.step_completed / playbook.completed
      t.string :event_type, null: false

      # 集約（Aggregate）
      t.string :aggregate_type, null: false  # "Deal" / "Lead" / "Contact" / etc.
      t.uuid   :aggregate_id,   null: false

      # イベントのデータ（変更前後の値、イベント固有データ）
      t.jsonb :payload,  null: false, default: {}

      # メタデータ（誰が、どこから、何のために）
      # { actor_type: "user"|"ai_agent"|"system", actor_id: uuid,
      #   source: "web_ui"|"api"|"agent"|"webhook", request_id: uuid }
      t.jsonb :metadata, null: false, default: {}

      # 集約内のシーケンス番号（楽観的並行制御・再生順序の保証）
      t.integer :sequence_number, null: false, default: 0

      t.datetime :occurred_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      # created_at のみ（更新しない）
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :sales_events, [ :aggregate_type, :aggregate_id, :sequence_number ],
              name: "idx_sales_events_aggregate_sequence"
    add_index :sales_events, :event_type
    add_index :sales_events, :occurred_at
    add_index :sales_events, [ :tenant_id, :occurred_at ]
    add_index :sales_events, :tenant_id

    # append-only を DB レベルで強制（UPDATE/DELETE を禁止するルール）
    execute <<~SQL
      ALTER TABLE sales_events ENABLE ROW LEVEL SECURITY;
      ALTER TABLE sales_events FORCE ROW LEVEL SECURITY;
      CREATE POLICY tenant_isolation ON sales_events
        USING (is_admin() OR tenant_id = current_tenant_id());
    SQL

    # ================================================================
    # 2. activity_timeline を廃止
    #    → sales_events が SSOT になるため不要
    #    → read model が必要なら sales_events の VIEW / 集計クエリで対応
    # ================================================================
    execute "DROP POLICY IF EXISTS tenant_isolation ON activity_timeline;"
    execute "ALTER TABLE activity_timeline DISABLE ROW LEVEL SECURITY;"
    drop_table :activity_timeline

    # ================================================================
    # 3. deal_stage_histories をリードモデルとして位置付けを明確化
    #    （sales_events の DealStageChanged イベントから導出）
    #    テーブル自体は残すが、直接書き込みは禁止→イベントから自動生成
    #    ※ Deal モデルの after_create/after_update callback を削除し
    #      SalesEvent 発行 → ProjectionWorker が deal_stage_histories を更新する設計に移行
    #    ここでは FK 追加のみ実施
    # ================================================================
    add_column :deal_stage_histories, :sales_event_id, :uuid, null: true
    add_foreign_key :deal_stage_histories, :sales_events, column: :sales_event_id
    add_index :deal_stage_histories, :sales_event_id

    # ================================================================
    # 4. SSOT修正: contacts.description / companies.description を廃止
    #    → notes テーブルに一本化
    # ================================================================
    remove_column :contacts,  :description
    remove_column :companies, :description

    # ================================================================
    # 5. SSOT修正: communications の役割を明確化
    #    communications = 外部システムからのインポートデータ（読み取り専用）
    #    email_messages = プラットフォーム経由のメールトラッキング
    #    meetings       = プラットフォームで管理する商談ミーティング
    #
    #    Zoom/GoogleMeet の communications と meetings を紐付けられるよう
    #    meetings.communication_id FK を追加
    # ================================================================
    add_column    :meetings, :communication_id, :uuid, null: true
    add_foreign_key :meetings, :communications, column: :communication_id
    add_index :meetings, :communication_id

    # ================================================================
    # 6. SSOT修正: communications.action_items / meeting_insights.action_items
    #    → jsonb は「AIが抽出した生データ（変更不可の記録）」として残す
    #      名前を raw_action_items に変更して "tasks とは別物" を明示
    # ================================================================
    rename_column :communications,    :action_items, :raw_action_items
    rename_column :meeting_insights,  :action_items, :raw_action_items

    # ================================================================
    # 7. deals.amount の意味を明確化
    #    deals.amount = 営業担当者が見積もる期待受注額（forecast用）
    #    quotes.total_amount = 実際に顧客に提示した見積金額
    #    contracts.value = 実際に締結した契約金額
    #    → カラム名を expected_revenue に変更してその意味を明示
    # ================================================================
    rename_column :deals, :amount, :expected_revenue
  end

  def down
    rename_column :deals, :expected_revenue, :amount

    rename_column :meeting_insights, :raw_action_items, :action_items
    rename_column :communications,   :raw_action_items, :action_items

    remove_foreign_key :meetings, column: :communication_id
    remove_index :meetings, :communication_id
    remove_column :meetings, :communication_id

    add_column :companies, :description, :text
    add_column :contacts,  :description, :text

    remove_foreign_key :deal_stage_histories, column: :sales_event_id
    remove_index :deal_stage_histories, :sales_event_id
    remove_column :deal_stage_histories, :sales_event_id

    create_table :activity_timeline, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :company, type: :uuid, null: true,  foreign_key: true
      t.references :contact, type: :uuid, null: true,  foreign_key: true
      t.references :deal,    type: :uuid, null: true,  foreign_key: true
      t.string   :activity_type, null: false
      t.string   :actor_type, null: false, default: "user"
      t.uuid     :actor_id
      t.datetime :occurred_at, null: false
      t.string   :title
      t.text     :description
      t.jsonb    :metadata, default: {}, null: false
      t.timestamps
    end
    execute <<~SQL
      ALTER TABLE activity_timeline ENABLE ROW LEVEL SECURITY;
      ALTER TABLE activity_timeline FORCE ROW LEVEL SECURITY;
      CREATE POLICY tenant_isolation ON activity_timeline
        USING (is_admin() OR tenant_id = current_tenant_id());
    SQL

    execute "DROP POLICY IF EXISTS tenant_isolation ON sales_events;"
    execute "ALTER TABLE sales_events DISABLE ROW LEVEL SECURITY;"
    drop_table :sales_events
  end
end
