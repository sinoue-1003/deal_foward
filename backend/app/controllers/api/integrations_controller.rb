module Api
  class IntegrationsController < BaseController
    INTEGRATION_TYPES = %w[slack teams zoom google_meet salesforce hubspot gmail].freeze

    # GET /api/integrations
    def index
      # Ensure all integration types exist in DB
      INTEGRATION_TYPES.each do |type|
        Integration.find_or_create_by!(integration_type: type)
      end

      integrations = Integration.all.order(:integration_type)
      render json: integrations
    end

    # POST /api/integrations/:id/connect
    def connect
      integration = Integration.find(params[:id])
      integration.update!(
        status: "connected",
        config: params[:config] || {},
        last_synced_at: Time.current,
        error_message: nil
      )
      render json: integration
    end

    # DELETE /api/integrations/:id (disconnect)
    def disconnect
      integration = Integration.find(params[:id])
      integration.update!(status: "disconnected", config: {})
      render json: integration
    end

    # POST /api/integrations/:id/sync
    def sync
      integration = Integration.find(params[:id])
      return render json: { error: "Not connected" }, status: :unprocessable_entity unless integration.status == "connected"

      # In production, this would trigger actual sync jobs
      integration.update!(last_synced_at: Time.current)

      WebhookNotifierService.notify(
        event: "integration_synced",
        payload: { type: integration.integration_type }
      )

      render json: { message: "Sync triggered", integration: integration }
    end
  end
end
