module TenantScoping
  extend ActiveSupport::Concern

  included do
    before_action :set_tenant_context
    around_action :scope_to_tenant
  end

  private

  def set_tenant_context
    return if admin_request? # admin はテナント不要

    tenant = resolve_tenant
    unless tenant&.active?
      render json: { error: "Tenant not found or inactive" }, status: :unauthorized and return
    end
    Current.tenant = tenant
  end

  # admin: app.is_admin = 'true' で RLS をバイパス
  # 通常: app.current_tenant_id をセットしてテナント分離
  def scope_to_tenant
    conn = ActiveRecord::Base.connection
    if admin_request?
      conn.execute("SET LOCAL app.is_admin = 'true'")
      conn.execute("SET LOCAL app.current_tenant_id = ''")
    else
      conn.execute("SET LOCAL app.current_tenant_id = '#{conn.quote_string(Current.tenant.id)}'")
      conn.execute("SET LOCAL app.is_admin = 'false'")
    end
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

  def admin_request?
    return @admin_request if defined?(@admin_request)
    admin_key = ENV["ADMIN_API_KEY"].to_s
    @admin_request = admin_key.present? &&
      ActiveSupport::SecurityUtils.secure_compare(
        request.headers["X-Admin-Api-Key"].to_s,
        admin_key
      )
  end
end
