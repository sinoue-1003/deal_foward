class FixSsotRemainingIssues < ActiveRecord::Migration[8.1]
  def up
    # ================================================================
    # string → User FK 修正（SSOT違反を解消）
    # ================================================================

    # tasks.assigned_to (string) → assigned_to_id (uuid FK)
    add_column      :tasks, :assigned_to_id, :uuid, null: true
    add_foreign_key :tasks, :users, column: :assigned_to_id
    add_index       :tasks, :assigned_to_id
    remove_column   :tasks, :assigned_to

    # playbook_steps.executed_by (string) → executed_by_id (uuid FK)
    add_column      :playbook_steps, :executed_by_id, :uuid, null: true
    add_foreign_key :playbook_steps, :users, column: :executed_by_id
    add_index       :playbook_steps, :executed_by_id
    remove_column   :playbook_steps, :executed_by

    # playbook_executions.executed_by (string) → executed_by_id (uuid FK)
    add_column      :playbook_executions, :executed_by_id, :uuid, null: true
    add_foreign_key :playbook_executions, :users, column: :executed_by_id
    add_index       :playbook_executions, :executed_by_id
    remove_column   :playbook_executions, :executed_by

    # agent_reports.reviewed_by (string) → reviewed_by_id (uuid FK)
    add_column      :agent_reports, :reviewed_by_id, :uuid, null: true
    add_foreign_key :agent_reports, :users, column: :reviewed_by_id
    add_index       :agent_reports, :reviewed_by_id
    remove_column   :agent_reports, :reviewed_by

    # ================================================================
    # deals.next_action / next_action_date を削除
    # → タスク管理は tasks テーブルに一本化（SSOT）
    # ================================================================
    remove_column :deals, :next_action
    remove_column :deals, :next_action_date

    # ================================================================
    # chat_sessions.messages (jsonb) を削除
    # → chat_messages テーブルに一本化（SSOT）
    # ================================================================
    remove_column :chat_sessions, :messages

    # ================================================================
    # deal_products — 商談と製品の直接紐付け（見積なしでも管理可能）
    # ================================================================
    create_table :deal_products, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant,  type: :uuid, null: false, foreign_key: true
      t.references :deal,    type: :uuid, null: false, foreign_key: true
      t.references :product, type: :uuid, null: false, foreign_key: true
      t.string   :name,          null: false   # 製品名（非正規化）
      t.integer  :quantity,      null: false, default: 1
      t.decimal  :unit_price,    precision: 15, scale: 2
      t.decimal  :total_price,   precision: 15, scale: 2
      t.string   :billing_period  # monthly/annual/one_time
      t.timestamps
    end
    add_index :deal_products, [ :deal_id, :product_id ], unique: true
    add_index :deal_products, :tenant_id

    execute <<~SQL
      ALTER TABLE deal_products ENABLE ROW LEVEL SECURITY;
      ALTER TABLE deal_products FORCE ROW LEVEL SECURITY;
      CREATE POLICY tenant_isolation ON deal_products
        USING (is_admin() OR tenant_id = current_tenant_id());
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS tenant_isolation ON deal_products;"
    execute "ALTER TABLE deal_products DISABLE ROW LEVEL SECURITY;"
    drop_table :deal_products

    add_column :chat_sessions, :messages, :jsonb, default: [], null: false

    add_column :deals, :next_action_date, :date
    add_column :deals, :next_action, :string

    add_column      :agent_reports, :reviewed_by, :string
    remove_foreign_key :agent_reports, column: :reviewed_by_id
    remove_index    :agent_reports, :reviewed_by_id
    remove_column   :agent_reports, :reviewed_by_id

    add_column      :playbook_executions, :executed_by, :string
    remove_foreign_key :playbook_executions, column: :executed_by_id
    remove_index    :playbook_executions, :executed_by_id
    remove_column   :playbook_executions, :executed_by_id

    add_column      :playbook_steps, :executed_by, :string
    remove_foreign_key :playbook_steps, column: :executed_by_id
    remove_index    :playbook_steps, :executed_by_id
    remove_column   :playbook_steps, :executed_by_id

    add_column      :tasks, :assigned_to, :string
    remove_foreign_key :tasks, column: :assigned_to_id
    remove_index    :tasks, :assigned_to_id
    remove_column   :tasks, :assigned_to_id
  end
end
