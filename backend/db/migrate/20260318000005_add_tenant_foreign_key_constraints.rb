class AddTenantForeignKeyConstraints < ActiveRecord::Migration[8.1]
  # Run this migration AFTER backfilling tenant_id for all existing rows.
  # In development/staging with no existing data this can run immediately
  # after 20260318000004.

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
    integrations
    agent_runs
  ].freeze

  def up
    TENANT_TABLES.each do |table|
      change_column_null table, :tenant_id, false
      add_foreign_key table, :tenants, column: :tenant_id
    end
  end

  def down
    TENANT_TABLES.each do |table|
      remove_foreign_key table, column: :tenant_id
      change_column_null table, :tenant_id, true
    end
  end
end
