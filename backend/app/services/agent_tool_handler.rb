class AgentToolHandler
  class ApprovalRequired < StandardError
    attr_reader :data

    def initialize(data)
      @data = data
      super("Human approval required: #{data[:action_description]}")
    end
  end

  def initialize(agent_run:)
    @agent_run = agent_run
  end

  def execute(tool_name, input)
    log_tool_call(tool_name, input)
    result = dispatch(tool_name, input.transform_keys(&:to_s))
    log_tool_result(tool_name, result)
    result
  rescue ApprovalRequired
    raise
  rescue StandardError => e
    { error: e.message }
  end

  private

  def dispatch(tool_name, input)
    case tool_name
    when "get_context"            then tool_get_context(input)
    when "get_communications"     then tool_get_communications(input)
    when "get_playbook"           then tool_get_playbook(input)
    when "update_step"            then tool_update_step(input)
    when "report_action"          then tool_report_action(input)
    when "request_human_approval" then tool_request_human_approval(input)
    when "send_message"           then tool_send_message(input)
    when "schedule_meeting"       then tool_schedule_meeting(input)
    else
      { error: "Unknown tool: #{tool_name}" }
    end
  end

  # ── Internal tools ──────────────────────────────────────────────────────────

  def tool_get_context(input)
    company_id = input["company_id"]
    return { error: "company_id required" } if company_id.blank?

    company = Company.find_by(id: company_id)
    return { error: "Company not found" } unless company

    comms     = Communication.where(company: company).order(recorded_at: :desc).limit(5)
    playbook  = Playbook.where(company: company, status: "active").last
    deal      = Deal.where(company: company).order(created_at: :desc).first

    {
      company: company.as_json(only: %i[id name industry website]),
      contacts: company.contacts.as_json(only: %i[id name email title]),
      recent_communications: comms.as_json(only: %i[id channel content recorded_at sentiment]),
      active_playbook: playbook ? playbook.as_json.merge(status_summary: playbook.status_summary) : nil,
      deal: deal&.as_json(only: %i[id title stage amount]),
      recommended_next_action: playbook&.next_action&.dig("action_type")
    }
  end

  def tool_get_communications(input)
    company_id = input["company_id"]
    scope = Communication.all
    scope = scope.where(company_id: company_id) if company_id.present?
    scope = scope.where(channel: input["channel"]) if input["channel"].present?
    limit = [input["limit"].to_i.positive? ? input["limit"].to_i : 10, 50].min
    scope.order(recorded_at: :desc).limit(limit).as_json(only: %i[id channel content recorded_at sentiment])
  end

  def tool_get_playbook(input)
    pb = Playbook.find_by(id: input["playbook_id"])
    return { error: "Playbook not found" } unless pb

    pb.as_json.merge(status_summary: pb.status_summary)
  end

  def tool_update_step(input)
    pb = Playbook.find_by(id: input["playbook_id"])
    return { error: "Playbook not found" } unless pb

    idx   = input["step_index"].to_i
    steps = pb.steps.dup
    return { error: "Step not found" } if steps[idx].nil?

    steps[idx] = steps[idx].merge(
      "status"       => input["status"],
      "result"       => input["result"],
      "completed_at" => Time.current.iso8601
    )

    new_current = steps.index { |s| s["status"] == "pending" } || pb.current_step
    pb.update!(steps: steps, current_step: new_current)

    PlaybookExecution.create!(
      playbook:    pb,
      step_index:  idx,
      status:      input["status"],
      result:      input["result"],
      executed_by: "ai_agent",
      executed_at: Time.current
    )

    { success: true, playbook: pb.as_json.merge(status_summary: pb.status_summary) }
  end

  def tool_report_action(input)
    report = AgentReport.create!(
      company:                  Company.find_by(id: input["company_id"]),
      action_taken:             input["action_taken"],
      insights:                 input["insights"] || {},
      next_recommended_actions: Array(input["next_recommended_actions"]),
      status:                   "completed"
    )

    WebhookNotifierService.notify(
      event:   "agent_report_submitted",
      payload: { report_id: report.id, action: report.action_taken }
    )

    { success: true, report_id: report.id }
  end

  def tool_request_human_approval(input)
    raise ApprovalRequired.new(
      action_description: input["action_description"],
      urgency:            input["urgency"] || "medium",
      proposed_message:   input["proposed_message"]
    )
  end

  # ── External tools (stub-safe; relies on Integration config) ────────────────

  def tool_send_message(input)
    channel   = input["channel"]
    recipient = input["recipient"]
    message   = input["message"]

    return { error: "channel, recipient, and message are required" } if [channel, recipient, message].any?(&:blank?)

    integration = Integration.find_by(integration_type: channel)
    unless integration&.status == "connected"
      return { error: "#{channel} integration is not connected. Please connect it in the integrations settings." }
    end

    # Dispatch to channel-specific sender
    case channel
    when "slack"
      send_slack_message(integration, recipient, message)
    when "email"
      send_email_message(recipient, input["subject"], message)
    when "teams"
      send_teams_message(integration, recipient, message)
    else
      { error: "Unsupported message channel: #{channel}" }
    end
  end

  def tool_schedule_meeting(input)
    platform       = input["platform"]
    attendee_email = input["attendee_email"]
    title          = input["title"]

    return { error: "platform, attendee_email, and title are required" } if [platform, attendee_email, title].any?(&:blank?)

    integration = Integration.find_by(integration_type: platform)
    unless integration&.status == "connected"
      return { error: "#{platform} integration is not connected. Please connect it in the integrations settings." }
    end

    {
      success: true,
      status:  "scheduled",
      message: "Meeting '#{title}' with #{attendee_email} has been queued for scheduling via #{platform}.",
      note:    "Full calendar API integration is pending."
    }
  end

  # ── Channel helpers ──────────────────────────────────────────────────────────

  def send_slack_message(integration, recipient, message)
    token = integration.config&.dig("access_token") || integration.config&.dig("bot_token")
    return { error: "Slack access token not configured" } if token.blank?

    response = Net::HTTP.post(
      URI("https://slack.com/api/chat.postMessage"),
      { channel: recipient, text: message }.to_json,
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{token}"
    )
    body = JSON.parse(response.body)
    body["ok"] ? { success: true, ts: body["ts"] } : { error: body["error"] }
  rescue StandardError => e
    { error: "Slack API error: #{e.message}" }
  end

  def send_email_message(recipient, subject, message)
    {
      success: true,
      status:  "queued",
      message: "Email to #{recipient} with subject '#{subject}' queued. SMTP integration pending full configuration."
    }
  end

  def send_teams_message(integration, recipient, message)
    {
      success: true,
      status:  "queued",
      message: "Teams message to #{recipient} queued. Teams Graph API integration pending full configuration."
    }
  end

  # ── Logging ──────────────────────────────────────────────────────────────────

  def log_tool_call(tool_name, input)
    calls = @agent_run.tool_calls || []
    calls << { tool: tool_name, input: input, called_at: Time.current.iso8601 }
    @agent_run.update_column(:tool_calls, calls)
  end

  def log_tool_result(tool_name, result)
    calls = @agent_run.tool_calls || []
    if calls.last&.dig("tool") == tool_name
      calls.last["output"] = result
      @agent_run.update_column(:tool_calls, calls)
    end
  end
end
