module Api
  class DealsController < BaseController
    # GET /api/deals
    def index
      deals = Deal.includes(:company, :contact).order(created_at: :desc)
      deals = deals.where(stage: params[:stage]) if params[:stage].present?
      render json: deals.map { |d|
        d.as_json.merge(
          company_name: d.company&.name,
          contact_name: d.contact&.name
        )
      }
    end

    # GET /api/deals/:id
    def show
      deal = Deal.find(params[:id])
      playbooks = Playbook.where(company: deal.company).order(created_at: :desc)
      render json: deal.as_json.merge(
        company: deal.company,
        contact: deal.contact,
        playbooks: playbooks.map { |pb| pb.as_json.merge(status_summary: pb.status_summary) }
      )
    end

    # POST /api/deals
    def create
      deal = Deal.create!(deal_params)
      render json: deal, status: :created
    end

    # PATCH /api/deals/:id
    def update
      deal = Deal.find(params[:id])
      deal.update!(deal_params)
      render json: deal
    end

    # DELETE /api/deals/:id
    def destroy
      Deal.find(params[:id]).destroy
      head :no_content
    end

    private

    def deal_params
      params.permit(:title, :company_id, :contact_id, :stage, :amount, :probability, :owner, :close_date, :notes)
    end
  end
end
