module Api
  class GmailImportController < BaseController
    # GET /api/gmail/preview
    def preview
      access_token = gmail_access_token
      domains = GmailImportService.preview(access_token: access_token)
      render json: {
        connected: access_token.present?,
        domains:   domains
      }
    end

    # POST /api/gmail/import
    # Body: {
    #   domains: [{ domain:, company_name:, contacts: [{name:, email:}] }],
    #   include_emails: true/false,
    #   analyze:        true/false
    # }
    def import
      selected = params[:domains]
      return render json: { error: "domains is required" }, status: :bad_request if selected.blank?

      include_emails = ActiveModel::Type::Boolean.new.cast(params[:include_emails])
      analyze        = ActiveModel::Type::Boolean.new.cast(params[:analyze])

      # 1. Create companies + contacts
      result = GmailImportService.import(selected_domains: selected)

      # 2. Optionally import email content as Communications
      email_result = { emails_imported: 0, emails_skipped: 0 }
      if include_emails
        access_token = gmail_access_token
        email_result = if access_token.present?
          GmailImportService.import_emails(
            selected_domains: selected,
            access_token:     access_token,
            analyze:          analyze
          )
        else
          GmailImportService.import_demo_emails(
            selected_domains: selected,
            analyze:          analyze
          )
        end
      end

      render json: {
        message:           "インポート完了",
        companies_created: result[:companies_created],
        contacts_created:  result[:contacts_created],
        contact_skipped:   result[:contact_skipped],
        emails_imported:   email_result[:emails_imported],
        emails_skipped:    email_result[:emails_skipped]
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
