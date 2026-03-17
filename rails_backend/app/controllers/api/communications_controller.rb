module Api
  class CommunicationsController < BaseController
    # GET /api/communications
    def index
      comms = Communication.includes(:company, :contact)
        .order(recorded_at: :desc)

      comms = comms.where(channel: params[:channel]) if params[:channel].present?
      comms = comms.where(company_id: params[:company_id]) if params[:company_id].present?

      render json: comms.limit(50).map { |c|
        c.as_json.merge(
          company_name: c.company&.name,
          contact_name: c.contact&.name
        )
      }
    end

    # GET /api/communications/:id
    def show
      comm = Communication.find(params[:id])
      render json: comm.as_json.merge(
        company: comm.company,
        contact: comm.contact
      )
    end

    # POST /api/communications
    def create
      comm = Communication.create!(communication_params)

      # Auto-analyze if content present
      if comm.content.present? && comm.summary.blank?
        result = AiAnalysisService.new.analyze_communication(
          content: comm.content, channel: comm.channel
        )
        comm.update!(
          summary: result["summary"],
          sentiment: result["sentiment"],
          keywords: result["keywords"],
          action_items: result["action_items"],
          analyzed_at: Time.current
        )
      end

      WebhookNotifierService.notify(
        event: "new_communication",
        payload: { communication_id: comm.id, channel: comm.channel }
      )

      render json: comm, status: :created
    end

    # POST /api/communications/analyze
    def analyze
      comm = Communication.find(params[:id])
      result = AiAnalysisService.new.analyze_communication(
        content: comm.content, channel: comm.channel
      )
      comm.update!(
        summary: result["summary"],
        sentiment: result["sentiment"],
        keywords: result["keywords"],
        action_items: result["action_items"],
        analyzed_at: Time.current
      )
      render json: comm
    end

    private

    def communication_params
      params.permit(:company_id, :contact_id, :channel, :content, :recorded_at)
    end
  end
end
