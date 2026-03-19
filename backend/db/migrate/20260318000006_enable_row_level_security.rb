class EnableRowLevelSecurity < ActiveRecord::Migration[8.1]
  # Postgres RLS — テナント分離のベストプラクティス
  #
  # アーキテクチャ:
  #   - アプリは各リクエスト開始時に SET LOCAL app.current_tenant_id = '<uuid>' を実行
  #   - current_tenant_id() 関数がその値を取得
  #   - 各テーブルのポリシーが tenant_id = current_tenant_id() を評価
  #   - Rails DB接続ユーザーには BYPASSRLS を付与しない (マイグレーション用superuserは別)
  #
  # 注意: RLSはアプリDBユーザー (app_user) に対して有効。
  #       superuser/migration用ユーザーは BYPASSRLS を持つため影響なし。

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
    users
  ].freeze

  def up
    execute <<~SQL
      -- =========================================================
      -- ヘルパー関数: 現在のテナントIDを取得
      -- =========================================================
      CREATE OR REPLACE FUNCTION current_tenant_id()
      RETURNS uuid
      LANGUAGE sql
      STABLE
      AS $$
        SELECT NULLIF(current_setting('app.current_tenant_id', true), '')::uuid
      $$;

      -- =========================================================
      -- tenants テーブル: 自分のテナントのみ閲覧可能
      -- =========================================================
      ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
      ALTER TABLE tenants FORCE ROW LEVEL SECURITY;

      DROP POLICY IF EXISTS tenant_isolation ON tenants;
      CREATE POLICY tenant_isolation ON tenants
        USING (id = current_tenant_id());

      -- =========================================================
      -- users テーブル
      -- =========================================================
      ALTER TABLE users ENABLE ROW LEVEL SECURITY;
      ALTER TABLE users FORCE ROW LEVEL SECURITY;

      DROP POLICY IF EXISTS tenant_isolation ON users;
      CREATE POLICY tenant_isolation ON users
        USING (tenant_id = current_tenant_id());
    SQL

    ALL_TENANT_TABLES.each do |table|
      next if %w[users].include?(table) # already handled above

      execute <<~SQL
        ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY;
        ALTER TABLE #{table} FORCE ROW LEVEL SECURITY;

        DROP POLICY IF EXISTS tenant_isolation ON #{table};
        CREATE POLICY tenant_isolation ON #{table}
          USING (tenant_id = current_tenant_id());
      SQL
    end
  end

  def down
    execute "DROP FUNCTION IF EXISTS current_tenant_id();"

    (ALL_TENANT_TABLES + %w[tenants]).each do |table|
      execute <<~SQL
        DROP POLICY IF EXISTS tenant_isolation ON #{table};
        ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY;
      SQL
    end
  end
end
