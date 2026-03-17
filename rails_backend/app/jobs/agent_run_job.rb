class AgentRunJob < ApplicationJob
  queue_as :agent

  def perform(agent_run_id)
    run = AgentRun.find(agent_run_id)

    # Skip if already in a terminal state (e.g. rejected before job started)
    return if %w[completed failed].include?(run.status)

    AgentExecutorService.new(agent_run: run).call
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("[AgentRunJob] AgentRun not found: #{agent_run_id}")
  rescue StandardError => e
    Rails.logger.error("[AgentRunJob] Unhandled error for run #{agent_run_id}: #{e.message}")
    AgentRun.find_by(id: agent_run_id)&.update(status: "failed", error_message: e.message)
  end
end
