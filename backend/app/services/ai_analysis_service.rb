class AiAnalysisService
  def initialize
    @client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
  end

  def analyze_communication(content:, channel:)
    return empty_analysis if content.blank?

    prompt = <<~PROMPT
      以下は#{channel_label(channel)}のコミュニケーション内容です。分析して以下をJSON形式で返してください:

      1. summary: 内容の要約（200文字以内）
      2. sentiment: 全体的な感情トーン（"positive", "neutral", "negative"）
      3. keywords: 重要キーワード（最大10個のリスト）
      4. action_items: 次のアクション項目（最大5個のリスト）
      5. intent_signals: 購買意欲・ニーズのシグナル（リスト）

      必ずJSON形式のみで返してください。

      内容:
      #{content.to_s[0..4000]}
    PROMPT

    response = @client.messages(
      model: "claude-sonnet-4-6",
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }]
    )

    text = response.content.first.text
    json_str = text.match(/\{.*\}/m)&.to_s || text
    JSON.parse(json_str)
  rescue StandardError
    empty_analysis
  end

  def analyze_intent(messages:)
    return 0 if messages.blank?

    conversation = messages.map { |m| "#{m['role']}: #{m['content']}" }.join("\n")

    prompt = <<~PROMPT
      以下はチャットボットとの会話です。
      ユーザーの購買意欲・商談意欲を0-100のスコアで評価してください。
      スコアのみを整数で返してください。

      会話:
      #{conversation[0..2000]}
    PROMPT

    response = @client.messages(
      model: "claude-sonnet-4-6",
      max_tokens: 10,
      messages: [{ role: "user", content: prompt }]
    )

    response.content.first.text.strip.to_i.clamp(0, 100)
  rescue StandardError
    0
  end

  private

  def channel_label(channel)
    {
      "slack" => "Slack",
      "teams" => "Microsoft Teams",
      "zoom" => "Zoom商談録画",
      "google_meet" => "Google Meet録画",
      "email" => "メール",
      "salesforce" => "Salesforce",
      "hubspot" => "HubSpot"
    }.fetch(channel, channel)
  end

  def empty_analysis
    { "summary" => "", "sentiment" => "neutral", "keywords" => [], "action_items" => [], "intent_signals" => [] }
  end
end
