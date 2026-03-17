class PlaybookGeneratorService
  ACTION_TYPES = %w[
    send_slack_message schedule_meeting send_email
    update_crm create_followup_task send_proposal
    request_demo share_case_study follow_up_call
    wait_customer_response
  ].freeze

  EXECUTOR_TYPES = %w[ai human customer].freeze

  def initialize
    @client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
  end

  def generate_from_chat_session(session)
    context = build_context_from_session(session)
    generate(context: context, company: session.company, contact: session.contact)
  end

  def generate_from_communications(company:, contact: nil)
    comms = Communication.where(company: company).order(recorded_at: :desc).limit(10)
    context = comms.map { |c| "【#{c.channel}】#{c.summary || c.content.to_s[0..500]}" }.join("\n\n")
    generate(context: context, company: company, contact: contact)
  end

  def generate(context:, company:, contact: nil)
    prompt = <<~PROMPT
      以下は営業コミュニケーション情報です。この情報をもとに、受注に向けた営業プレイブックを作成してください。

      ## コミュニケーション情報
      #{context[0..3000]}

      ## 出力形式 (JSON)
      {
        "title": "プレイブックタイトル",
        "objective": "このプレイブックの目標",
        "situation_summary": "現在の状況サマリー（AIと人間が共有する文脈情報）",
        "steps": [
          {
            "step": 1,
            "action_type": "アクション種別 (#{ACTION_TYPES.join(', ')} のいずれか)",
            "executor_type": "実行者種別 (ai / human / customer のいずれか)",
            "channel": "使用チャンネル (slack/teams/zoom/google_meet/email/salesforce/hubspot/chatbot)",
            "target": "対象者・チャンネル名",
            "template": "実行すべき内容の詳細",
            "due_in_hours": 24,
            "status": "pending"
          }
        ]
      }

      ## executor_type の使い分け
      - "ai"       : AIエージェントが自律実行するステップ（メール送信・Slack送信・CRM更新など）
      - "human"    : 営業担当者が実行するステップ（判断が必要な会議・提案内容の最終確認など）
      - "customer" : 顧客のアクションを待つステップ（チャットbot経由で顧客が返信・承認したとき自動完了）

      顧客への連絡はAIが実行 (executor_type: "ai") し、顧客の返答を待つ場合は wait_customer_response (executor_type: "customer") を使うこと。
      ステップは3〜7個程度。必ずJSON形式のみで返してください。
    PROMPT

    response = @client.messages(
      model: "claude-sonnet-4-6",
      max_tokens: 2048,
      messages: [{ role: "user", content: prompt }]
    )

    text = response.content.first.text
    json_str = text.match(/\{.*\}/m)&.to_s || text
    data = JSON.parse(json_str)

    Playbook.create!(
      company: company,
      contact: contact,
      title: data["title"] || "新規プレイブック",
      objective: data["objective"],
      situation_summary: data["situation_summary"],
      steps: data["steps"] || [],
      status: "active",
      created_by: "ai_agent"
    )
  rescue StandardError => e
    Rails.logger.error("PlaybookGeneratorService error: #{e.message}")
    nil
  end

  private

  def build_context_from_session(session)
    messages = (session.messages || []).map { |m| "#{m['role']}: #{m['content']}" }.join("\n")
    company_name = session.company&.name || "不明な会社"
    "チャットセッション (会社: #{company_name})\n#{messages}"
  end
end
