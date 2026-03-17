module Api
  module Agent
    class ActionsController < Api::BaseController
      include AgentAuthentication

      # POST /api/agent/report
      def report
        report = AgentReport.create!(
          company: find_company,
          contact: find_contact,
          action_taken: params.require(:action_taken),
          insights: params[:insights] || {},
          next_recommended_actions: params[:next_recommended_actions] || [],
          status: params[:status] || "completed"
        )

        WebhookNotifierService.notify(
          event: "agent_report_submitted",
          payload: { report_id: report.id, action: report.action_taken }
        )

        render json: report, status: :created
      end

      # POST /api/agent/request_context
      def request_context
        company = find_company
        render json: build_full_context(company)
      end

      # POST /api/agent/trigger_playbook
      def trigger_playbook
        company = find_company
        contact = find_contact
        playbook = PlaybookGeneratorService.new.generate_from_communications(
          company: company, contact: contact
        )
        render json: playbook, status: :created
      end

      # GET /api/agent/communications
      def communications
        comms = Communication.all
        comms = comms.where(company_id: params[:company_id]) if params[:company_id].present?
        comms = comms.where(channel: params[:channel]) if params[:channel].present?
        render json: comms.order(recorded_at: :desc).limit(20)
      end

      # GET /api/agent/contacts/:company_id
      def contacts
        contacts = Contact.where(company_id: params[:company_id])
        render json: contacts
      end

      # GET /api/agent/playbook/:id
      def playbook
        pb = Playbook.find(params[:id])
        render json: pb.as_json.merge(status_summary: pb.status_summary)
      end

      # PATCH /api/agent/playbook/:id/step/:step_index
      def update_step
        pb = Playbook.find(params[:id])
        idx = params[:step_index].to_i
        steps = pb.steps.dup
        return render json: { error: "Step not found" }, status: :not_found if steps[idx].nil?

        steps[idx] = steps[idx].merge(
          "status" => params[:status],
          "result" => params[:result],
          "completed_at" => Time.current.iso8601
        )

        new_current = steps.index { |s| s["status"] == "pending" } || pb.current_step
        pb.update!(steps: steps, current_step: new_current)

        PlaybookExecution.create!(
          playbook: pb, step_index: idx,
          status: params[:status], result: params[:result],
          executed_by: "ai_agent", executed_at: Time.current
        )

        render json: pb.as_json.merge(status_summary: pb.status_summary)
      end

      private

      def find_company
        Company.find(params[:company_id]) if params[:company_id].present?
      end

      def find_contact
        Contact.find(params[:contact_id]) if params[:contact_id].present?
      end

      def build_full_context(company)
        return { error: "company_id required" } unless company

        comms = Communication.where(company: company).order(recorded_at: :desc).limit(5)
        playbook = Playbook.where(company: company, status: "active").last
        deal = Deal.where(company: company).order(created_at: :desc).first

        {
          company: company,
          contacts: company.contacts,
          recent_communications: comms,
          active_playbook: playbook ? playbook.as_json.merge(status_summary: playbook.status_summary) : nil,
          deal: deal,
          recommended_next_action: playbook&.next_action&.dig("action_type")
        }
      end
    end
  end
end
