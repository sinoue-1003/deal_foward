class UpdateRlsPoliciesForAdmin < ActiveRecord::Migration[8.1]
  # admin モードでは RLS を完全バイパスする
  #
  # 仕組み:
  #   - SET LOCAL app.is_admin = 'true' をセットしたセッションは全テーブルにフルアクセス
  #   - is_admin() 関数がセッション変数を評価
  #   - ポリシー条件: is_admin() OR tenant_id = current_tenant_id()
  #
  # セキュリティ上の注意:
  #   - app.is_admin のセットはアプリ側で厳密に管理すること
  #   - admin API は ADMIN_API_KEY 環境変数で認証した場合のみ許可
  #   - SET LOCAL はトランザクション境界でリセットされるため漏洩しない

  ALL_TABLES = %w[
    tenants
    users
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
      -- =========================================================
      -- ヘルパー関数: 現在のセッションが admin かどうか
      -- =========================================================
      CREATE OR REPLACE FUNCTION is_admin()
      RETURNS boolean
      LANGUAGE sql
      STABLE
      AS $$
        SELECT current_setting('app.is_admin', true) = 'true'
      $$;
    SQL

    # tenants テーブル: admin は全テナント閲覧可能
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON tenants;
      CREATE POLICY tenant_isolation ON tenants
        USING (
          is_admin()
          OR id = current_tenant_id()
        );
    SQL

    # その他の全テーブル: admin は全テナントデータにアクセス可能
    (ALL_TABLES - %w[tenants]).each do |table|
      execute <<~SQL
        DROP POLICY IF EXISTS tenant_isolation ON #{table};
        CREATE POLICY tenant_isolation ON #{table}
          USING (
            is_admin()
            OR tenant_id = current_tenant_id()
          );
      SQL
    end
  end

  def down
    execute "DROP FUNCTION IF EXISTS is_admin();"

    # admin バイパスなしの元のポリシーに戻す
    execute <<~SQL
      DROP POLICY IF EXISTS tenant_isolation ON tenants;
      CREATE POLICY tenant_isolation ON tenants
        USING (id = current_tenant_id());
    SQL

    (ALL_TABLES - %w[tenants]).each do |table|
      execute <<~SQL
        DROP POLICY IF EXISTS tenant_isolation ON #{table};
        CREATE POLICY tenant_isolation ON #{table}
          USING (tenant_id = current_tenant_id());
      SQL
    end
  end
end
