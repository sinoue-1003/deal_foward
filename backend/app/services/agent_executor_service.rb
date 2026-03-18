class AgentExecutorService
  MAX_ITERATIONS = 20

  TOOLS = [
    {
      name: "get_context",
      description: "会社の全コンテキスト（連絡先・直近通信・アクティブプレイブック・商談）を取得する",
      input_schema: {
        type: "object",
        properties: {
          company_id: { type: "string", description: "対象会社のUUID" }
        },
        required: ["company_id"]
      }
    },
    {
      name: "get_communications",
      description: "直近のSlack/Teams/Zoom/メール等の通信データを取得する",
      input_schema: {
        type: "object",
        properties: {
          company_id: { type: "string" },
          channel:    { type: "string", enum: %w[slack teams zoom google_meet email salesforce hubspot] },
          limit:      { type: "integer" }
        },
        required: ["company_id"]
      }
    },
    {
      name: "get_playbook",
      description: "プレイブックの詳細とstatus_summaryを取得する",
      input_schema: {
        type: "object",
        properties: {
          playbook_id: { type: "string" }
        },
        required: ["playbook_id"]
      }
    },
    {
      name: "update_step",
      description: "プレイブックのステップ完了を報告する",
      input_schema: {
        type: "object",
        properties: {
          playbook_id: { type: "string" },
          step_index:  { type: "integer" },
          status:      { type: "string", enum: %w[completed failed skipped] },
          result:      { type: "string", description: "実行結果の説明" }
        },
        required: %w[playbook_id step_index status]
      }
    },
    {
      name: "report_action",
      description: "エージェントが行ったアクションをプラットフォームに報告する",
      input_schema: {
        type: "object",
        properties: {
          company_id:               { type: "string" },
          action_taken:             { type: "string" },
          insights:                 { type: "object" },
          next_recommended_actions: { type: "array", items: { type: "string" } }
        },
        required: ["action_taken"]
      }
    },
    {
      name: "request_human_approval",
      description: "人間の承認が必要なアクションを実行前に確認依頼する。承認されるまでエージェントは停止する。",
      input_schema: {
        type: "object",
        properties: {
          action_description: { type: "string", description: "人間に承認を求めるアクションの説明" },
          urgency:            { type: "string", enum: %w[low medium high] },
          proposed_message:   { type: "string", description: "送信予定のメッセージ内容（あれば）" }
        },
        required: ["action_description"]
      }
    },
    {
      name: "send_message",
      description: "Slackまたはメールでメッセージを送信する（Integration設定が必要）",
      input_schema: {
        type: "object",
        properties: {
          channel:   { type: "string", enum: %w[slack email teams] },
          recipient: { type: "string", description: "送信先のSlackユーザーIDまたはメールアドレス" },
          message:   { type: "string" },
          subject:   { type: "string", description: "メールの場合の件名" }
        },
        required: %w[channel recipient message]
      }
    },
    {
      name: "create_gmail_draft",
      description: "Gmailの下書きを作成する。人間がGmailで内容を確認・編集してから送信できる。送信前に人間にレビューさせたいメールに使用する。",
      input_schema: {
        type: "object",
        properties: {
          to:      { type: "string", description: "宛先メールアドレス" },
          subject: { type: "string", description: "メールの件名" },
          body:    { type: "string", description: "メール本文" },
          cc:      { type: "string", description: "CCのメールアドレス（任意）" }
        },
        required: %w[to subject body]
      }
    },
    {
      name: "schedule_meeting",
      description: "Google MeetまたはZoomのMTGをカレンダーに作成する",
      input_schema: {
        type: "object",
        properties: {
          platform:       { type: "string", enum: %w[google_meet zoom] },
          attendee_email: { type: "string" },
          title:          { type: "string" },
          proposed_time:  { type: "string", description: "ISO8601形式の希望日時" },
          duration_mins:  { type: "integer" }
        },
        required: %w[platform attendee_email title]
      }
    }
  ].freeze

  def initialize(agent_run:)
    @agent_run   = agent_run
    @client      = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    @tool_handler = AgentToolHandler.new(agent_run: agent_run)
  end

  def call
    @agent_run.update!(status: "analyzing")
    messages = @agent_run.messages.dup

    # Build initial user message if starting fresh
    if messages.empty?
      messages << {
        role:    "user",
        content: initial_user_message
      }
    end

    iteration = 0
    loop do
      iteration += 1
      if iteration > MAX_ITERATIONS
        @agent_run.update!(status: "failed", error_message: "Max iterations (#{MAX_ITERATIONS}) exceeded")
        return
      end

      @agent_run.update!(status: "executing") if @agent_run.status == "analyzing"

      Rails.logger.info("[AgentExecutor] Run #{@agent_run.id} — iteration #{iteration}, sending #{messages.size} messages to Claude")

      response = @client.messages(
        model:    "claude-sonnet-4-6",
        system:   build_system_prompt,
        messages: messages,
        tools:    TOOLS,
        max_tokens: 4096
      )

      # Append assistant response to conversation
      assistant_content = response.content.map do |block|
        if block.type == "text"
          { type: "text", text: block.text }
        elsif block.type == "tool_use"
          { type: "tool_use", id: block.id, name: block.name, input: block.input }
        end
      end.compact

      messages << { role: "assistant", content: assistant_content }
      @agent_run.update!(messages: messages)

      break if response.stop_reason == "end_turn"

      # Process tool calls
      tool_result_content = []
      response.content.select { |b| b.type == "tool_use" }.each do |tool_use|
        Rails.logger.info("[AgentExecutor] Calling tool: #{tool_use.name} with #{tool_use.input}")

        result = @tool_handler.execute(tool_use.name, tool_use.input)
        tool_result_content << {
          type:        "tool_result",
          tool_use_id: tool_use.id,
          content:     result.to_json
        }
      end

      messages << { role: "user", content: tool_result_content }
      @agent_run.update!(messages: messages)
    end

    # Finalize
    @agent_run.update!(status: "completed")
    WebhookNotifierService.notify(
      event:   "agent_run_completed",
      payload: { run_id: @agent_run.id, company_id: @agent_run.company_id }
    )
    Rails.logger.info("[AgentExecutor] Run #{@agent_run.id} completed after #{iteration} iterations")

  rescue AgentToolHandler::ApprovalRequired => e
    Rails.logger.info("[AgentExecutor] Run #{@agent_run.id} paused for human approval: #{e.data[:action_description]}")
    @agent_run.update!(
      status:           "waiting_approval",
      pending_approval: e.data,
      messages:         messages
    )

  rescue StandardError => e
    Rails.logger.error("[AgentExecutor] Run #{@agent_run.id} failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    @agent_run.update!(status: "failed", error_message: e.message)
    raise
  end

  private

  def build_system_prompt
    company  = @agent_run.company
    playbook = @agent_run.playbook

    context_snippet = if company
      begin
        context = {
          company:  company.as_json(only: %i[id name industry]),
          contacts: company.contacts.as_json(only: %i[id name email title])
        }
        context.to_json
      rescue StandardError
        "{}"
      end
    else
      "{}"
    end

    playbook_snippet = if playbook
      begin
        playbook.status_summary.to_json
      rescue StandardError
        "{}"
      end
    else
      "null"
    end

    <<~PROMPT
      あなたはDeal Forwardプラットフォームの営業AIエージェントです。

      ## あなたの役割
      - 会社のコミュニケーションデータを分析し、営業プレイブックを実行する
      - 人間の営業担当者と協力して商談を前進させる
      - 重要なアクション（メッセージ送信・MTG設定）の前は必ず request_human_approval を呼んで承認を求める

      ## 対象会社の基本コンテキスト
      #{context_snippet}

      ## アクティブなプレイブック状態
      #{playbook_snippet}

      ## ルール
      1. send_message または schedule_meeting を呼ぶ前に、必ず request_human_approval を呼ぶこと
      2. メール送信の場合、直接送信より create_gmail_draft で下書き作成を優先すること（人間がレビューできる）
      3. すべてのアクション実行後に report_action で記録すること
      4. 分析・実行が完了したら end_turn で停止すること
      5. 一度に実行しすぎず、段階的に確認しながら進めること

      現在時刻: #{Time.current.iso8601}
    PROMPT
  end

  def initial_user_message
    parts = ["営業活動の状況を分析し、次のアクションを実行してください。"]

    if @agent_run.company
      parts << "対象会社ID: #{@agent_run.company_id}"
      parts << "まず get_context ツールで最新のコンテキストを取得してください。"
    end

    if @agent_run.playbook
      parts << "対象プレイブックID: #{@agent_run.playbook_id}"
      parts << "get_playbook ツールでプレイブックの詳細を確認し、次のペンディングステップを実行してください。"
    end

    parts.join("\n")
  end
end
