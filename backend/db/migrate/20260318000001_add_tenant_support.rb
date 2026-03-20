class AddTenantSupport < ActiveRecord::Migration[8.1]
  # integrations は tenant スコープでユニーク制約が変わるため別扱い
  BUSINESS_TABLES = %i[
    companies
    contacts
    chat_sessions
    communications
    agent_reports
    playbooks
    playbook_steps
    playbook_executions
    deals
    deal_contacts
    agent_runs
  ].freeze

  def up
    create_table :tenants, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :plan,   null: false, default: "starter"   # starter, growth, enterprise
      t.string :status, null: false, default: "active"    # active, suspended, cancelled
      t.string :agent_api_key_digest  # BCrypt digest of agent API key
      t.jsonb  :settings, null: false, default: {}
      t.timestamps
    end
    add_index :tenants, :slug, unique: true
    add_index :tenants, :status

    create_table :users, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :tenant, null: false, foreign_key: true, type: :uuid
      t.string :email, null: false
      t.string :name
      t.string :role, null: false, default: "member"  # admin, member, viewer
      t.string :password_digest
      t.jsonb  :settings, null: false, default: {}
      t.timestamps
    end
    add_index :users, [ :tenant_id, :email ], unique: true
    add_index :users, :role

    # ビジネステーブルに tenant_id を追加 (未実行のため NOT NULL + FK を一括適用)
    BUSINESS_TABLES.each do |table|
      add_column table, :tenant_id, :uuid, null: false
      add_index table, :tenant_id
      add_foreign_key table, :tenants, column: :tenant_id
    end

    # integrations: テナント単位のユニーク制約に変更
    remove_index :integrations, :integration_type
    add_column :integrations, :tenant_id, :uuid, null: false
    add_index :integrations, :tenant_id
    add_foreign_key :integrations, :tenants, column: :tenant_id
    add_index :integrations, [ :tenant_id, :integration_type ], unique: true
  end

  def down
    BUSINESS_TABLES.each do |table|
      remove_foreign_key table, column: :tenant_id
      remove_index table, :tenant_id
      remove_column table, :tenant_id
    end

    remove_foreign_key :integrations, column: :tenant_id
    remove_index :integrations, [ :tenant_id, :integration_type ]
    remove_index :integrations, :tenant_id
    remove_column :integrations, :tenant_id
    add_index :integrations, :integration_type, unique: true

    drop_table :users
    drop_table :tenants
  end
end
