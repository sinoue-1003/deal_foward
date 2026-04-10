class AddBusinessFields < ActiveRecord::Migration[8.1]
  def up
    # ================================================================
    # companies — 企業マスタ
    # ================================================================
    add_column :companies, :corporate_number, :string       # 法人番号（13桁）
    add_column :companies, :founding_year,    :integer      # 設立年
    add_column :companies, :listed_market,    :string       # 上場市場 (TSE Prime/Standard/Growth/未上場 etc.)
    add_column :companies, :fiscal_month,     :integer      # 決算月 (1-12)
    add_column :companies, :prefecture,       :string       # 都道府県
    add_column :companies, :postal_code,      :string       # 郵便番号
    add_column :companies, :linkedin_url,     :string       # LinkedIn URL

    # ================================================================
    # contacts — 個人連絡先
    # ================================================================
    add_column :contacts, :linkedin_url,      :string                                 # LinkedIn URL
    add_column :contacts, :timezone,          :string                                 # タイムゾーン (Asia/Tokyo 等)
    add_column :contacts, :language,          :string,  default: "ja"                # 言語 (ja/en/etc.)
    add_column :contacts, :preferred_channel, :string                                 # 優先連絡チャネル (email/phone/slack/teams)
    add_column :contacts, :do_not_contact,    :boolean, default: false, null: false   # 連絡禁止フラグ
    add_column :contacts, :last_contacted_at, :datetime                               # 最終連絡日時

    # ================================================================
    # deals — 営業案件
    # ================================================================
    add_column :deals, :source,              :string                               # リードソース (inbound/outbound/referral/partner/event/web/other)
    add_column :deals, :deal_type,           :string, default: "new_business"      # 案件タイプ (new_business/expansion/renewal/upsell/cross_sell)
    add_column :deals, :currency,            :string, default: "JPY"              # 通貨
    add_column :deals, :budget,              :decimal, precision: 15, scale: 2    # 予算
    add_column :deals, :expected_start_date, :date                                 # 開始予定日
    add_column :deals, :forecast_category,   :string                               # フォーキャスト区分 (commit/best_case/pipeline/omitted)
    add_column :deals, :competitors,         :jsonb, default: [], null: false      # 競合情報
    add_column :deals, :pain_points,         :text                                 # 顧客の課題
    add_column :deals, :decision_criteria,   :text                                 # 意思決定基準
    add_column :deals, :next_action,         :string                               # 次アクション内容
    add_column :deals, :next_action_date,    :date                                 # 次アクション予定日
    add_column :deals, :won_reason,          :string                               # 受注理由

    add_index :deals, :deal_type
    add_index :deals, :forecast_category

    # ================================================================
    # playbooks — プレイブック
    # ================================================================
    add_reference :playbooks, :deal, type: :uuid, foreign_key: true, null: true    # 案件との紐付け
    add_column    :playbooks, :priority,     :string, default: "medium"            # 優先度 (high/medium/low)
    add_column    :playbooks, :tags,         :jsonb,  default: [], null: false     # タグ配列
    add_column    :playbooks, :due_date,     :date                                 # 期限
    add_column    :playbooks, :completed_at, :datetime                             # 完了日時

    # ================================================================
    # playbook_steps — プレイブックステップ
    # ================================================================
    add_column :playbook_steps, :description,       :text                                   # ステップの詳細説明
    add_column :playbook_steps, :approval_required, :boolean, default: false, null: false   # 承認必要フラグ
    add_column :playbook_steps, :approved_by,       :string                                 # 承認者
    add_column :playbook_steps, :approved_at,       :datetime                               # 承認日時
    add_column :playbook_steps, :output,            :text                                   # 実行結果 / 出力

    # ================================================================
    # communications — コミュニケーション記録
    # ================================================================
    add_reference :communications, :deal, type: :uuid, foreign_key: true, null: true   # 案件との紐付け
    add_column    :communications, :subject,          :string                           # 件名（メール等）
    add_column    :communications, :direction,        :string                           # 方向 (inbound/outbound)
    add_column    :communications, :duration_seconds, :integer                          # 会話時間（秒）
    add_column    :communications, :participants,     :jsonb, default: [], null: false  # 参加者一覧
    add_column    :communications, :next_steps,       :jsonb, default: [], null: false  # 次のステップ

    # ================================================================
    # chat_sessions — チャットセッション
    # ================================================================
    add_column    :chat_sessions, :visitor_id,         :string                           # 訪問者 ID (cookie/fingerprint)
    add_column    :chat_sessions, :page_url,           :string                           # チャット開始ページ URL
    add_column    :chat_sessions, :source,             :string                           # 流入元 (organic/paid/social/referral/direct/email)
    add_column    :chat_sessions, :utm_params,         :jsonb, default: {}, null: false  # UTM パラメータ
    add_column    :chat_sessions, :lead_captured,      :boolean, default: false, null: false   # リード取得フラグ
    add_column    :chat_sessions, :follow_up_required, :boolean, default: false, null: false   # フォローアップ必要フラグ
    add_reference :chat_sessions, :assigned_to, type: :uuid,                                   # 担当ユーザー
                  foreign_key: { to_table: :users }, null: true

    # ================================================================
    # agent_reports — AIエージェントレポート
    # ================================================================
    add_reference :agent_reports, :deal,     type: :uuid, foreign_key: true, null: true   # 案件との紐付け
    add_reference :agent_reports, :playbook, type: :uuid, foreign_key: true, null: true   # プレイブックとの紐付け
    add_column    :agent_reports, :title,            :string                               # レポートタイトル
    add_column    :agent_reports, :report_type,      :string, default: "activity"         # レポートタイプ (activity/analysis/recommendation/alert)
    add_column    :agent_reports, :confidence_score, :integer                             # 信頼度スコア (0-100)
    add_column    :agent_reports, :reviewed_by,      :string                              # 確認者名
    add_column    :agent_reports, :reviewed_at,      :datetime                            # 確認日時

    # ================================================================
    # agent_runs — AIエージェント実行セッション
    # ================================================================
    add_reference :agent_runs, :contact, type: :uuid, foreign_key: true, null: true   # 連絡先との紐付け
    add_reference :agent_runs, :deal,    type: :uuid, foreign_key: true, null: true   # 案件との紐付け
    add_column    :agent_runs, :run_type,     :string, default: "execution"            # 実行タイプ (analysis/execution/monitoring/reporting)
    add_column    :agent_runs, :summary,      :text                                    # 実行サマリー
    add_column    :agent_runs, :tokens_used,  :integer                                 # 使用トークン数
    add_column    :agent_runs, :cost_cents,   :integer                                 # コスト（セント単位）
    add_column    :agent_runs, :completed_at, :datetime                                # 完了日時

    # ================================================================
    # tasks — 営業タスク / アクティビティ管理（新規テーブル）
    # ================================================================
    create_table :tasks, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,        type: :uuid, null: false, foreign_key: true
      t.references :deal,          type: :uuid, null: true,  foreign_key: true
      t.references :company,       type: :uuid, null: true,  foreign_key: true
      t.references :contact,       type: :uuid, null: true,  foreign_key: true
      t.references :playbook_step, type: :uuid, null: true,  foreign_key: true

      t.string   :title,       null: false                           # タスク名
      t.text     :description                                        # 詳細説明
      t.string   :task_type,   default: "other"                     # 種別 (call/email/meeting/demo/proposal/follow_up/other)
      t.string   :status,      null: false, default: "pending"      # ステータス (pending/in_progress/completed/cancelled)
      t.string   :priority,    null: false, default: "medium"       # 優先度 (high/medium/low)
      t.string   :created_by,  null: false, default: "ai_agent"     # 作成者 (ai_agent or ユーザー名)
      t.string   :assigned_to                                        # 担当者
      t.datetime :due_at                                             # 期限日時
      t.datetime :reminder_at                                        # リマインダー日時
      t.datetime :completed_at                                       # 完了日時
      t.text     :outcome                                            # 結果 / アウトカム

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :priority
    add_index :tasks, :task_type
    add_index :tasks, :due_at
    add_index :tasks, :tenant_id

    # tasks テーブルへ RLS (Row Level Security) を適用
    execute <<~SQL
      ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
      ALTER TABLE tasks FORCE ROW LEVEL SECURITY;
      CREATE POLICY tenant_isolation ON tasks
        USING (is_admin() OR tenant_id = current_tenant_id());
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS tenant_isolation ON tasks;"
    execute "ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;"
    drop_table :tasks

    # agent_runs
    remove_reference :agent_runs, :deal,    foreign_key: true
    remove_reference :agent_runs, :contact, foreign_key: true
    %i[completed_at cost_cents tokens_used summary run_type].each do |col|
      remove_column :agent_runs, col
    end

    # agent_reports
    remove_reference :agent_reports, :playbook, foreign_key: true
    remove_reference :agent_reports, :deal,     foreign_key: true
    %i[reviewed_at reviewed_by confidence_score report_type title].each do |col|
      remove_column :agent_reports, col
    end

    # chat_sessions
    remove_reference :chat_sessions, :assigned_to, foreign_key: { to_table: :users }
    %i[follow_up_required lead_captured utm_params source page_url visitor_id].each do |col|
      remove_column :chat_sessions, col
    end

    # communications
    remove_reference :communications, :deal, foreign_key: true
    %i[next_steps participants duration_seconds direction subject].each do |col|
      remove_column :communications, col
    end

    # playbook_steps
    %i[output approved_at approved_by approval_required description].each do |col|
      remove_column :playbook_steps, col
    end

    # playbooks
    %i[completed_at due_date tags priority].each do |col|
      remove_column :playbooks, col
    end
    remove_reference :playbooks, :deal, foreign_key: true

    # deals
    remove_index  :deals, :forecast_category
    remove_index  :deals, :deal_type
    %i[won_reason next_action_date next_action decision_criteria pain_points
       competitors forecast_category expected_start_date budget currency deal_type source].each do |col|
      remove_column :deals, col
    end

    # contacts
    %i[last_contacted_at do_not_contact preferred_channel language timezone linkedin_url].each do |col|
      remove_column :contacts, col
    end

    # companies
    %i[linkedin_url postal_code prefecture fiscal_month listed_market founding_year corporate_number].each do |col|
      remove_column :companies, col
    end
  end
end
