module Api
  class ContractsController < BaseController
    # GET /api/contracts
    def index
      contracts = Contract.includes(:company, :deal, :owner).order(created_at: :desc)
      contracts = contracts.where(status: params[:status])       if params[:status].present?
      contracts = contracts.where(company_id: params[:company_id]) if params[:company_id].present?
      contracts = contracts.expiring_soon                          if params[:expiring_soon] == "true"
      render json: contracts.map { |c| contract_summary(c) }
    end

    # GET /api/contracts/:id
    def show
      contract = Contract.includes(:company, :deal, :contact, :owner).find(params[:id])
      render json: contract.as_json.merge(
        company: contract.company&.slice("id", "name"),
        deal:    contract.deal&.slice("id", "title", "stage"),
        contact: contract.contact&.slice("id", "first_name", "last_name", "email"),
        owner:   contract.owner&.slice("id", "name")
      )
    end

    # POST /api/contracts
    def create
      render json: Contract.create!(contract_params), status: :created
    end

    # PATCH /api/contracts/:id
    def update
      contract = Contract.find(params[:id])
      contract.update!(contract_params)
      render json: contract
    end

    # DELETE /api/contracts/:id
    def destroy
      Contract.find(params[:id]).destroy
      head :no_content
    end

    private

    def contract_summary(contract)
      contract.as_json(only: %i[
        id contract_number status contract_type
        value arr mrr currency billing_period
        start_date end_date renewal_date auto_renew
        created_at
      ]).merge(
        company_name: contract.company&.name,
        deal_title:   contract.deal&.title,
        owner_name:   contract.owner&.name
      )
    end

    def contract_params
      params.permit(
        :deal_id, :company_id, :contact_id, :quote_id, :owner_id,
        :status, :contract_type, :start_date, :end_date, :renewal_date,
        :auto_renew, :value, :currency, :billing_period,
        :terms, :terms_url, :signed_by, :signed_at,
        :terminated_at, :termination_reason
      )
    end
  end
end
