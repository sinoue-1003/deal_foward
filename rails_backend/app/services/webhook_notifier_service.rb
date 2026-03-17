class WebhookNotifierService
  def self.notify(event:, payload:)
    url = ENV["AGENT_WEBHOOK_URL"]
    return unless url.present?

    HTTParty.post(
      url,
      body: { event: event, data: payload, timestamp: Time.current.iso8601 }.to_json,
      headers: { "Content-Type" => "application/json" },
      timeout: 5
    )
  rescue StandardError => e
    Rails.logger.warn("Webhook notification failed: #{e.message}")
  end
end
