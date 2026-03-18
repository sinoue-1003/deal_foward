module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    # TenantScoping のテナント必須チェックをスキップし、admin 専用の認証・スコープに差し替える
    skip_before_action :set_tenant_context
    skip_around_action :scope_to_tenant

    before_action :authenticate_admin!
    around_action :scope_as_admin
  end

  private

  def authenticate_admin!
    api_key = request.headers["X-Admin-Api-Key"].to_s
    unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, ENV.fetch("ADMIN_API_KEY", ""))
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
    Current.admin = true
  end

  # admin セッションでは app.is_admin = 'true' をセット → RLS が全テナントデータを許可する
  # app.current_tenant_id は空のまま (テナント横断アクセス)
  def scope_as_admin
    conn = ActiveRecord::Base.connection
    conn.execute("SET LOCAL app.is_admin = 'true'")
    conn.execute("SET LOCAL app.current_tenant_id = ''")
    yield
  ensure
    Current.admin = false
  end
end
