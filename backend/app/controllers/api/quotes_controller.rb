module Api
  class QuotesController < BaseController
    # GET /api/quotes
    def index
      quotes = Quote.includes(:deal, :contact, :line_items).order(created_at: :desc)
      quotes = quotes.where(deal_id: params[:deal_id]) if params[:deal_id].present?
      quotes = quotes.where(status: params[:status])   if params[:status].present?
      render json: quotes.map { |q| quote_summary(q) }
    end

    # GET /api/quotes/:id
    def show
      quote = Quote.includes(:line_items, :deal, :contact).find(params[:id])
      render json: quote.as_json.merge(
        line_items: quote.line_items,
        deal:       quote.deal&.slice("id", "title", "stage"),
        contact:    quote.contact&.slice("id", "first_name", "last_name", "email")
      )
    end

    # POST /api/quotes
    def create
      quote = Quote.create!(quote_params)
      render json: quote, status: :created
    end

    # PATCH /api/quotes/:id
    def update
      quote = Quote.find(params[:id])
      quote.update!(quote_params)
      render json: quote
    end

    # DELETE /api/quotes/:id
    def destroy
      Quote.find(params[:id]).destroy
      head :no_content
    end

    private

    def quote_summary(quote)
      quote.as_json(only: %i[
        id quote_number status total_amount currency
        valid_until sent_at accepted_at created_at
      ]).merge(
        deal_title:   quote.deal&.title,
        contact_name: quote.contact&.full_name
      )
    end

    def quote_params
      params.permit(
        :deal_id, :contact_id, :status, :valid_until,
        :discount_amount, :tax_amount, :currency,
        :notes, :terms
      )
    end
  end
end
