class AddTenantIdToAllTables < ActiveRecord::Migration[8.1]
  TENANT_TABLES = %i[
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
    # Add tenant_id to all business tables (nullable first to allow backfilling)
    TENANT_TABLES.each do |table|
      add_column table, :tenant_id, :uuid, null: true
      add_index table, :tenant_id
    end

    # integrations: drop old single-integration-type unique index, re-scope per tenant
    remove_index :integrations, :integration_type
    add_column :integrations, :tenant_id, :uuid, null: true
    add_index :integrations, :tenant_id
    add_index :integrations, [ :tenant_id, :integration_type ], unique: true

    # After backfilling in production, apply NOT NULL + FK constraints via:
    # rails db:migrate:add_tenant_not_null_constraints
    # (see migration 20260318000006)
  end

  def down
    TENANT_TABLES.each do |table|
      remove_index table, :tenant_id
      remove_column table, :tenant_id
    end

    remove_index :integrations, [ :tenant_id, :integration_type ]
    remove_index :integrations, :tenant_id
    remove_column :integrations, :tenant_id
    add_index :integrations, :integration_type, unique: true
  end
end
