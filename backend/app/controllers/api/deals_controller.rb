module Api
  class DealsController < BaseController
    # GET /api/deals
    def index
      deals = Deal.includes(:company, :contacts, :owner).order(created_at: :desc)
      deals = deals.where(stage: params[:stage])       if params[:stage].present?
      deals = deals.where(owner_id: params[:owner_id]) if params[:owner_id].present?
      render json: deals.map { |d| deal_summary(d) }
    end

    # GET /api/deals/:id
    def show
      deal = Deal.includes(:contacts, :owner, :products, :tasks, :quotes).find(params[:id])
      playbooks = Playbook.where(company: deal.company).order(created_at: :desc)
      render json: deal.as_json.merge(
        owner:     deal.owner&.slice("id", "name", "email"),
        company:   deal.company,
        contacts:  deal.deal_contacts.includes(:contact).map { |dc|
          dc.contact.as_json(only: %i[id first_name last_name email position]).merge(role: dc.role)
        },
        products:  deal.deal_products.includes(:product).map { |dp|
          dp.as_json.merge(product_category: dp.product&.category)
        },
        tasks:     deal.tasks.open.order(due_at: :asc),
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

    def deal_summary(deal)
      deal.as_json(only: %i[
        id title stage expected_revenue probability currency
        close_date forecast_category deal_type source
        created_at updated_at
      ]).merge(
        company_name: deal.company&.name,
        owner_name:   deal.owner&.name,
        contacts:     deal.contacts.map { |c|
          { id: c.id, full_name: c.full_name, email: c.email }
        }
      )
    end

    def deal_params
      params.permit(
        :title, :company_id, :owner_id, :stage, :expected_revenue, :probability,
        :close_date, :notes, :lost_reason, :won_reason,
        :source, :deal_type, :currency, :budget, :expected_start_date,
        :forecast_category, :pain_points, :decision_criteria,
        competitors: []
      )
    end

    def assign_contacts(deal)
      deal.deal_contacts.destroy_all
      Array(params[:contact_ids]).each do |contact_id|
        deal.deal_contacts.create!(tenant: deal.tenant, contact_id: contact_id)
      end
    end
  end
end
