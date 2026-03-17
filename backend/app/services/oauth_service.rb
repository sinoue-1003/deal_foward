class OauthService
  PROVIDERS = {
    "slack" => {
      authorize_url:     "https://slack.com/oauth/v2/authorize",
      token_url:         "https://slack.com/api/oauth.v2.access",
      client_id_env:     "SLACK_CLIENT_ID",
      client_secret_env: "SLACK_CLIENT_SECRET",
      scopes:            "chat:write channels:read",
      token_method:      :post_form
    },
    "teams" => {
      authorize_url:     "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
      token_url:         "https://login.microsoftonline.com/common/oauth2/v2.0/token",
      client_id_env:     "TEAMS_CLIENT_ID",
      client_secret_env: "TEAMS_CLIENT_SECRET",
      scopes:            "https://graph.microsoft.com/Chat.ReadWrite offline_access",
      token_method:      :post_form
    },
    "zoom" => {
      authorize_url:     "https://zoom.us/oauth/authorize",
      token_url:         "https://zoom.us/oauth/token",
      client_id_env:     "ZOOM_CLIENT_ID",
      client_secret_env: "ZOOM_CLIENT_SECRET",
      scopes:            "meeting:read meeting:write",
      token_method:      :post_form_basic_auth
    },
    "google_meet" => {
      authorize_url:          "https://accounts.google.com/o/oauth2/v2/auth",
      token_url:              "https://oauth2.googleapis.com/token",
      client_id_env:          "GOOGLE_CLIENT_ID",
      client_secret_env:      "GOOGLE_CLIENT_SECRET",
      scopes:                 "https://www.googleapis.com/auth/calendar",
      token_method:           :post_form,
      extra_authorize_params: { access_type: "offline", prompt: "consent" }
    },
    "salesforce" => {
      authorize_url:     "https://login.salesforce.com/services/oauth2/authorize",
      token_url:         "https://login.salesforce.com/services/oauth2/token",
      client_id_env:     "SALESFORCE_CLIENT_ID",
      client_secret_env: "SALESFORCE_CLIENT_SECRET",
      scopes:            "api refresh_token",
      token_method:      :post_form
    },
    "hubspot" => {
      authorize_url:     "https://app.hubspot.com/oauth/authorize",
      token_url:         "https://api.hubapi.com/oauth/v1/token",
      client_id_env:     "HUBSPOT_CLIENT_ID",
      client_secret_env: "HUBSPOT_CLIENT_SECRET",
      scopes:            "contacts crm.objects.deals.read",
      token_method:      :post_form
    }
  }.freeze

  REDIRECT_URI = -> { ENV.fetch("OAUTH_REDIRECT_URI", "http://localhost:8000/api/oauth/callback") }
  STATE_TTL    = 10.minutes

  class OauthError < StandardError; end

  # Returns the full authorization URL to redirect the browser to.
  def self.authorize_url(integration_type, integration_id)
    provider = PROVIDERS[integration_type]
    raise OauthError, "Unknown provider: #{integration_type}" unless provider

    client_id = ENV[provider[:client_id_env]]
    raise OauthError, "#{provider[:client_id_env]} is not set" if client_id.blank?

    state = encode_state(integration_type: integration_type, integration_id: integration_id)

    params = {
      client_id:     client_id,
      redirect_uri:  REDIRECT_URI.call,
      response_type: "code",
      scope:         provider[:scopes],
      state:         state
    }.merge(provider[:extra_authorize_params] || {})

    "#{provider[:authorize_url]}?#{params.to_query}"
  end

  # Handles the OAuth callback: decodes state, exchanges code for tokens,
  # persists tokens to integration.config. Returns the updated Integration.
  def self.handle_callback(code:, state:, error: nil)
    decoded = decode_state(state)
    raise OauthError, "Invalid or expired state parameter" unless decoded

    integration_type = decoded["integration_type"]
    integration_id   = decoded["integration_id"]
    provider         = PROVIDERS[integration_type]
    raise OauthError, "Unknown provider in state: #{integration_type}" unless provider

    integration = Integration.find(integration_id)

    if error.present?
      integration.update!(status: "error", error_message: "OAuth denied: #{error}")
      raise OauthError, "OAuth authorization denied: #{error}"
    end

    tokens = exchange_code(provider, code)
    integration.update!(
      status:         "connected",
      config:         build_config(tokens),
      last_synced_at: Time.current,
      error_message:  nil
    )
    integration
  end

  # ── Private ──────────────────────────────────────────────────────────────────
  private_class_method def self.encode_state(integration_type:, integration_id:)
    payload = {
      "integration_type" => integration_type,
      "integration_id"   => integration_id,
      "issued_at"        => Time.current.to_i
    }.to_json
    Base64.urlsafe_encode64(payload, padding: false)
  end

  private_class_method def self.decode_state(state)
    return nil if state.blank?
    payload = JSON.parse(Base64.urlsafe_decode64(state))
    return nil if Time.current.to_i - payload["issued_at"].to_i > STATE_TTL.to_i
    payload
  rescue JSON::ParserError, ArgumentError
    nil
  end

  private_class_method def self.exchange_code(provider, code)
    client_id     = ENV.fetch(provider[:client_id_env])
    client_secret = ENV.fetch(provider[:client_secret_env])
    redirect_uri  = REDIRECT_URI.call

    response = case provider[:token_method]
    when :post_form
      HTTParty.post(
        provider[:token_url],
        body: {
          grant_type:    "authorization_code",
          code:          code,
          redirect_uri:  redirect_uri,
          client_id:     client_id,
          client_secret: client_secret
        },
        headers: { "Content-Type" => "application/x-www-form-urlencoded" }
      )
    when :post_form_basic_auth
      HTTParty.post(
        provider[:token_url],
        body: {
          grant_type:   "authorization_code",
          code:         code,
          redirect_uri: redirect_uri
        },
        headers: {
          "Content-Type"  => "application/x-www-form-urlencoded",
          "Authorization" => "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
        }
      )
    end

    body = response.parsed_response
    unless response.success? && body["access_token"].present?
      error_msg = body["error_description"] || body["error"] || "HTTP #{response.code}"
      raise OauthError, "Token exchange failed: #{error_msg}"
    end

    body
  end

  private_class_method def self.build_config(tokens)
    {
      "access_token"  => tokens["access_token"],
      "bot_token"     => tokens.dig("authed_user", "access_token"),  # Slack user token
      "refresh_token" => tokens["refresh_token"],
      "token_type"    => tokens["token_type"],
      "expires_in"    => tokens["expires_in"],
      "scope"         => tokens["scope"],
      "instance_url"  => tokens["instance_url"],  # Salesforce
      "obtained_at"   => Time.current.iso8601
    }.compact
  end
end
