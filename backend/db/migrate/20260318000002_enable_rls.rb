class EnableRls < ActiveRecord::Migration[8.1]
  # Postgres RLS によるテナント分離
  #
  # アーキテクチャ:
  #   - 各リクエスト開始時: SET LOCAL app.current_tenant_id = '<uuid>'
  #   - admin リクエスト時: SET LOCAL app.is_admin = 'true'
  #   - SET LOCAL はトランザクション境界でリセットされるため漏洩しない
  #   - Rails DB 接続ユーザーには BYPASSRLS を付与しない (migration 用 superuser は別)

  ALL_TENANT_TABLES = %w[
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
    execute <<~SQL
      -- 現在のテナント ID を取得するヘルパー関数
      CREATE OR REPLACE FUNCTION current_tenant_id()
      RETURNS uuid
      LANGUAGE sql
      STABLE
      AS $$
        SELECT NULLIF(current_setting('app.current_tenant_id', true), '')::uuid
      $$;

      -- admin セッションかどうかを判定するヘルパー関数
      CREATE OR REPLACE FUNCTION is_admin()
      RETURNS boolean
      LANGUAGE sql
      STABLE
      AS $$
        SELECT current_setting('app.is_admin', true) = 'true'
      $$;

      -- tenants テーブル: 自テナントのみ / admin は全テナント
      ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
      ALTER TABLE tenants FORCE ROW LEVEL SECURITY;
      CREATE POLICY tenant_isolation ON tenants
        USING (is_admin() OR id = current_tenant_id());

      -- users テーブル
      ALTER TABLE users ENABLE ROW LEVEL SECURITY;
      ALTER TABLE users FORCE ROW LEVEL SECURITY;
      CREATE POLICY tenant_isolation ON users
        USING (is_admin() OR tenant_id = current_tenant_id());
    SQL

    ALL_TENANT_TABLES.each do |table|
      execute <<~SQL
        ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY;
        ALTER TABLE #{table} FORCE ROW LEVEL SECURITY;
        CREATE POLICY tenant_isolation ON #{table}
          USING (is_admin() OR tenant_id = current_tenant_id());
      SQL
    end
  end

  def down
    execute "DROP FUNCTION IF EXISTS current_tenant_id();"
    execute "DROP FUNCTION IF EXISTS is_admin();"

    (ALL_TENANT_TABLES + %w[tenants users]).each do |table|
      execute <<~SQL
        DROP POLICY IF EXISTS tenant_isolation ON #{table};
        ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY;
      SQL
    end
  end
end
