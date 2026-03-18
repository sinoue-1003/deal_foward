module Api
  class OauthController < BaseController
    FRONTEND_BASE = -> { ENV.fetch("FRONTEND_URL", "http://localhost:5173") }

    # GET /api/oauth/:integration_type/authorize
    # Redirects the browser to the OAuth provider's authorization page.
    def authorize
      integration_type = params[:integration_type]
      unless Integration::TYPES.include?(integration_type)
        return render json: { error: "Unknown integration type: #{integration_type}" }, status: :bad_request
      end

      integration = Integration.find_or_create_by!(integration_type: integration_type)
      url = OauthService.authorize_url(integration_type, integration.id)
      redirect_to url, allow_other_host: true
    rescue OauthService::OauthError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # GET /api/oauth/callback?code=xxx&state=yyy
    # OAuth provider redirects here after user grants (or denies) consent.
    def callback
      integration = OauthService.handle_callback(
        code:  params[:code],
        state: params[:state],
        error: params[:error]
      )
      redirect_path = integration.integration_type == "gmail" \
        ? "#{FRONTEND_BASE.call}/gmail-import?connected=true" \
        : "#{FRONTEND_BASE.call}/communications?connected=#{integration.integration_type}"
      redirect_to redirect_path, allow_other_host: true
    rescue OauthService::OauthError => e
      redirect_to "#{FRONTEND_BASE.call}/communications?oauth_error=#{CGI.escape(e.message)}",
                  allow_other_host: true
    rescue ActiveRecord::RecordNotFound
      redirect_to "#{FRONTEND_BASE.call}/communications?oauth_error=integration_not_found",
                  allow_other_host: true
    end
  end
end
