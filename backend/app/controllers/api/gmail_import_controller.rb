module Api
  class GmailImportController < BaseController
    # GET /api/gmail/preview
    # Returns domain-grouped contacts extracted from Gmail.
    # Uses stored OAuth token if Gmail integration is connected; otherwise demo data.
    def preview
      access_token = gmail_access_token
      domains = GmailImportService.preview(access_token: access_token)
      render json: {
        connected: access_token.present?,
        domains:   domains
      }
    end

    # POST /api/gmail/import
    # Body: { domains: [{ domain:, company_name:, contacts: [{name:, email:}] }] }
    def import
      selected = params[:domains]
      return render json: { error: "domains is required" }, status: :bad_request if selected.blank?

      result = GmailImportService.import(selected_domains: selected)

      render json: {
        message:           "インポート完了",
        companies_created: result[:companies_created],
        contacts_created:  result[:contacts_created],
        skipped:           result[:skipped]
      }
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def gmail_access_token
      integration = Integration.find_by(integration_type: "gmail", status: "connected")
      integration&.config&.dig("access_token")
    end
  end
end
