module Api
  class DealsController < BaseController
    # GET /api/deals
    def index
      deals = Deal.includes(:company, :contacts).order(created_at: :desc)
      deals = deals.where(stage: params[:stage]) if params[:stage].present?
      render json: deals.map { |d|
        d.as_json.merge(
          company_name: d.company&.name,
          contacts: d.contacts.map { |c| { id: c.id, name: c.name } }
        )
      }
    end

    # GET /api/deals/:id
    def show
      deal = Deal.includes(:contacts).find(params[:id])
      playbooks = Playbook.where(company: deal.company).order(created_at: :desc)
      render json: deal.as_json.merge(
        company: deal.company,
        contacts: deal.deal_contacts.includes(:contact).map { |dc|
          dc.contact.as_json.merge(role: dc.role)
        },
        playbooks: playbooks.map { |pb| pb.as_json.merge(status_summary: pb.status_summary) }
      )
    end

    # POST /api/deals
    def create
      deal = Deal.create!(deal_params)
      assign_contacts(deal) if params[:contact_ids].present?
      render json: deal, status: :created
    end

    # PATCH /api/deals/:id
    def update
      deal = Deal.find(params[:id])
      deal.update!(deal_params)
      assign_contacts(deal) if params[:contact_ids].present?
      render json: deal
    end

    # DELETE /api/deals/:id
    def destroy
      Deal.find(params[:id]).destroy
      head :no_content
    end

    private

    def deal_params
      params.permit(:title, :company_id, :stage, :amount, :probability, :owner, :close_date, :notes, :lost_reason)
    end

    def assign_contacts(deal)
      deal.deal_contacts.destroy_all
      Array(params[:contact_ids]).each do |contact_id|
        deal.deal_contacts.create!(contact_id: contact_id)
      end
    end
  end
end
