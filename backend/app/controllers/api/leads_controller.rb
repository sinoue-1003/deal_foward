module Api
  class LeadsController < BaseController
    # GET /api/leads
    def index
      leads = Lead.order(created_at: :desc)
      leads = leads.where(status: params[:status]) if params[:status].present?
      leads = leads.where(source: params[:source]) if params[:source].present?
      leads = leads.where("score >= ?", params[:min_score]) if params[:min_score].present?
      render json: leads
    end

    # GET /api/leads/:id
    def show
      render json: Lead.find(params[:id])
    end

    # POST /api/leads
    def create
      lead = Lead.create!(lead_params)
      render json: lead, status: :created
    end

    # PATCH /api/leads/:id
    def update
      lead = Lead.find(params[:id])
      lead.update!(lead_params)
      render json: lead
    end

    # POST /api/leads/:id/convert
    def convert
      lead     = Lead.find(params[:id])
      contact  = Contact.find(params[:contact_id])
      deal     = params[:deal_id].present? ? Deal.find(params[:deal_id]) : nil
      lead.convert!(contact: contact, deal: deal)
      render json: lead
    end

    # DELETE /api/leads/:id
    def destroy
      Lead.find(params[:id]).destroy
      head :no_content
    end

    private

    def lead_params
      params.permit(
        :first_name, :last_name, :email, :phone,
        :company_name, :job_title, :source, :status,
        :score, :assigned_to_id, :disqualified_reason,
        utm_params: {}, custom_fields: {}
      )
    end
  end
end
