module Api
  module Dashboard
    class OverviewsController < Api::BaseController
      def show
        render json: {
          active_playbooks: Playbook.where(status: "active").count,
          today_chat_sessions: ChatSession.where("created_at >= ?", Time.current.beginning_of_day).count,
          total_chat_sessions: ChatSession.count,
          analyzed_communications: Communication.where.not(analyzed_at: nil).count,
          total_communications: Communication.count,
          agent_reports_today: AgentReport.where("created_at >= ?", Time.current.beginning_of_day).count,
          total_agent_reports: AgentReport.count,
          pipeline_value: Deal.where.not(stage: ["closed_lost"]).sum(:expected_revenue).to_f,
          active_deals: Deal.where.not(stage: ["closed_won", "closed_lost"]).count,
          integrations_connected: Integration.where(status: "connected").count
        }
      end
    end
  end
end
