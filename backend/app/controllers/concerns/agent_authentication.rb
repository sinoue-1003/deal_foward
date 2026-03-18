module AgentAuthentication
  extend ActiveSupport::Concern

  included do
    # エージェントリクエストは TenantScoping の set_tenant_context の代わりに
    # X-Agent-Api-Key でテナントを特定する
    skip_before_action :set_tenant_context
    skip_around_action :scope_to_tenant

    before_action :authenticate_agent_and_set_tenant!
    around_action :scope_agent_to_tenant
  end

  private

  def authenticate_agent_and_set_tenant!
    api_key = request.headers["X-Agent-Api-Key"].to_s

    # 後方互換: 環境変数のグローバルキーは開発環境のみ許可
    if Rails.env.development? && api_key == ENV["AGENT_API_KEY"].to_s
      # 開発時はテナントをスラッグ or ヘッダーで特定
      tenant = Tenant.find_by(slug: request.headers["X-Tenant-Slug"]) ||
               Tenant.first
      return render json: { error: "No tenant configured" }, status: :service_unavailable unless tenant
      Current.tenant = tenant
      return
    end

    # 本番: テナントごとの API キーで認証
    tenant = find_tenant_by_agent_api_key(api_key)
    unless tenant&.active?
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    Current.tenant = tenant
  end

  def scope_agent_to_tenant
    ActiveRecord::Base.connection.execute(
      "SET LOCAL app.current_tenant_id = '#{ActiveRecord::Base.connection.quote_string(Current.tenant.id)}'"
    )
    yield
  ensure
    Current.tenant = nil
  end

  def find_tenant_by_agent_api_key(raw_key)
    return nil if raw_key.blank?
    # api_key_digest が設定されているテナントを全件チェック (テナント数が増えたらキャッシュ推奨)
    Tenant.where.not(agent_api_key_digest: nil).find do |t|
      t.valid_agent_api_key?(raw_key)
    end
  end
end
