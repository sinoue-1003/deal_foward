class ChatbotService
  SYSTEM_PROMPT = <<~PROMPT
    あなたは営業支援AIアシスタントです。
    訪問者のニーズを理解し、製品・サービスへの関心を引き出してください。
    会話は日本語で行い、簡潔かつ親切に応答してください。
    ユーザーの課題や目標を聞き出し、具体的な商談につなげることが目的です。
  PROMPT

  def initialize
    @client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    @analysis_service = AiAnalysisService.new
  end

  def respond(session:, user_message:)
    messages = build_messages(session.messages, user_message)

    response = @client.messages(
      model: "claude-sonnet-4-6",
      max_tokens: 512,
      system: SYSTEM_PROMPT,
      messages: messages
    )

    bot_reply = response.content.first.text

    # Update session messages
    updated_messages = session.messages + [
      { "role" => "user", "content" => user_message, "timestamp" => Time.current.iso8601 },
      { "role" => "assistant", "content" => bot_reply, "timestamp" => Time.current.iso8601 }
    ]

    # Recalculate intent score every 3 messages
    new_intent = if updated_messages.size % 6 == 0
      @analysis_service.analyze_intent(messages: updated_messages)
    else
      session.intent_score
    end

    session.update!(
      messages: updated_messages,
      intent_score: [session.intent_score, new_intent].max
    )

    # Trigger playbook if high intent detected
    if session.intent_score >= 70 && session.intent_score_before_last_save < 70
      PlaybookGeneratorService.new.generate_from_chat_session(session)
      WebhookNotifierService.notify(
        event: "high_intent_detected",
        payload: { session_id: session.id, intent_score: session.intent_score }
      )
    end

    # Auto-complete any pending customer step in the active playbook
    complete_customer_step!(session, user_message)

    { reply: bot_reply, intent_score: session.intent_score }
  rescue StandardError => e
    { reply: "申し訳ありません。しばらくお待ちください。", intent_score: session.intent_score }
  end

  private

  # When a customer sends a chatbot message, check if the active playbook
  # has a pending customer step and auto-complete it with their message.
  def complete_customer_step!(session, user_message)
    return unless session.company_id

    playbook = Playbook.where(company_id: session.company_id, status: "active").last
    return unless playbook

    steps = playbook.steps
    idx = steps.index { |s| s["status"] == "pending" && s["executor_type"] == "customer" }
    return unless idx

    steps = steps.dup
    steps[idx] = steps[idx].merge(
      "status"       => "completed",
      "executed_by"  => "customer",
      "completed_at" => Time.current.iso8601,
      "result"       => "顧客返信: #{user_message.to_s[0..300]}"
    )

    new_current = steps.index { |s| s["status"] == "pending" } || playbook.current_step
    playbook.update!(steps: steps, current_step: new_current)
    playbook.maybe_auto_complete!

    PlaybookExecution.create!(
      playbook:    playbook,
      step_index:  idx,
      status:      "completed",
      result:      "顧客返信: #{user_message.to_s[0..300]}",
      executed_by: "customer",
      executed_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error("ChatbotService#complete_customer_step! error: #{e.message}")
  end

  def build_messages(history, new_message)
    hist = (history || []).map { |m| { role: m["role"], content: m["content"] } }
    hist + [{ role: "user", content: new_message }]
  end
end
