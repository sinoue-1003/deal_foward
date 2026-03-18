class GmailService
  GMAIL_API_BASE = "https://gmail.googleapis.com/gmail/v1/users/me"
  TOKEN_URL      = "https://oauth2.googleapis.com/token"

  def initialize(integration)
    @integration = integration
  end

  # Gmail下書きを作成する。AIエージェントが人間レビュー用に下書きを用意する場合に使用。
  def create_draft(to:, subject:, body:, cc: nil)
    token = valid_access_token
    return { error: "Gmail access token not available" } if token.blank?

    mime    = build_mime(to: to, subject: subject, body: body, cc: cc)
    encoded = Base64.urlsafe_encode64(mime, padding: false)

    response = HTTParty.post(
      "#{GMAIL_API_BASE}/drafts",
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type"  => "application/json"
      },
      body: { message: { raw: encoded } }.to_json
    )

    if response.success?
      draft = response.parsed_response
      {
        success:  true,
        draft_id: draft["id"],
        message:  "Gmail下書きを作成しました。Gmailで内容を確認してから送信してください。"
      }
    else
      error_msg = response.parsed_response.dig("error", "message") || "HTTP #{response.code}"
      { error: "Gmail API error: #{error_msg}" }
    end
  rescue StandardError => e
    { error: "Gmail service error: #{e.message}" }
  end

  # メールを直接送信する。必ず request_human_approval で承認を得てから呼ぶこと。
  def send_email(to:, subject:, body:, cc: nil)
    token = valid_access_token
    return { error: "Gmail access token not available" } if token.blank?

    mime    = build_mime(to: to, subject: subject, body: body, cc: cc)
    encoded = Base64.urlsafe_encode64(mime, padding: false)

    response = HTTParty.post(
      "#{GMAIL_API_BASE}/messages/send",
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type"  => "application/json"
      },
      body: { raw: encoded }.to_json
    )

    if response.success?
      msg = response.parsed_response
      {
        success:   true,
        message_id: msg["id"],
        thread_id:  msg["threadId"],
        message:   "メールを送信しました (to: #{to}, subject: #{subject})"
      }
    else
      error_msg = response.parsed_response.dig("error", "message") || "HTTP #{response.code}"
      { error: "Gmail API error: #{error_msg}" }
    end
  rescue StandardError => e
    { error: "Gmail service error: #{e.message}" }
  end

  private

  # トークンが期限切れであればリフレッシュして有効なアクセストークンを返す
  def valid_access_token
    config       = @integration.config || {}
    obtained_at  = Time.parse(config["obtained_at"]) rescue nil
    expires_in   = config["expires_in"].to_i

    if obtained_at && expires_in > 0
      expiry = obtained_at + expires_in.seconds
      refresh_token!(config) if Time.current >= expiry - 5.minutes
      config = @integration.reload.config || {}
    end

    config["access_token"]
  end

  def refresh_token!(config)
    refresh_token = config["refresh_token"]
    return unless refresh_token.present?

    response = HTTParty.post(
      TOKEN_URL,
      body: {
        grant_type:    "refresh_token",
        refresh_token: refresh_token,
        client_id:     ENV["GOOGLE_CLIENT_ID"],
        client_secret: ENV["GOOGLE_CLIENT_SECRET"]
      },
      headers: { "Content-Type" => "application/x-www-form-urlencoded" }
    )

    if response.success?
      new_tokens = response.parsed_response
      @integration.update!(config: config.merge(
        "access_token" => new_tokens["access_token"],
        "expires_in"   => new_tokens["expires_in"],
        "obtained_at"  => Time.current.iso8601
      ))
    else
      Rails.logger.error("[GmailService] Token refresh failed: #{response.parsed_response}")
    end
  rescue StandardError => e
    Rails.logger.error("[GmailService] Token refresh error: #{e.message}")
  end

  # RFC 2822形式のMIMEメッセージを組み立てる
  def build_mime(to:, subject:, body:, cc: nil)
    lines = []
    lines << "From: me"
    lines << "To: #{to}"
    lines << "Cc: #{cc}" if cc.present?
    lines << "Subject: #{subject}"
    lines << "MIME-Version: 1.0"
    lines << "Content-Type: text/plain; charset=UTF-8"
    lines << "Content-Transfer-Encoding: 8bit"
    lines << ""
    lines << body
    lines.join("\r\n")
  end
end
