module TenantScoping
  extend ActiveSupport::Concern

  included do
    before_action :set_tenant_context
    around_action :scope_to_tenant
  end

  private

  # X-Tenant-Slug ヘッダーまたは subdomain からテナントを解決する
  # 実際の認証 (JWT/セッション) と組み合わせて使う
  def set_tenant_context
    tenant = resolve_tenant
    unless tenant&.active?
      render json: { error: "Tenant not found or inactive" }, status: :unauthorized and return
    end
    Current.tenant = tenant
  end

  # リクエストのライフサイクル全体で Postgres のセッション変数を設定する
  # SET LOCAL はトランザクション終了時に自動リセットされる
  def scope_to_tenant
    conn = ActiveRecord::Base.connection
    conn.execute("SET LOCAL app.current_tenant_id = '#{conn.quote_string(Current.tenant.id)}'")
    conn.execute("SET LOCAL app.is_admin = 'false'")  # 通常テナントリクエストでは admin バイパスを明示的に無効化
    yield
  ensure
    Current.tenant = nil
  end

  def resolve_tenant
    # 優先順位: X-Tenant-Id ヘッダー → X-Tenant-Slug ヘッダー → サブドメイン
    if (tenant_id = request.headers["X-Tenant-Id"].presence)
      Tenant.find_by(id: tenant_id)
    elsif (slug = request.headers["X-Tenant-Slug"].presence)
      Tenant.find_by(slug: slug)
    elsif (subdomain = request.subdomain.presence) && subdomain != "www"
      Tenant.find_by(slug: subdomain)
    end
  end
end
