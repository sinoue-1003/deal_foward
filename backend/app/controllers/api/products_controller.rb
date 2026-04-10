module Api
  class ProductsController < BaseController
    # GET /api/products
    def index
      products = Product.active.order(:name)
      products = products.where(category: params[:category])       if params[:category].present?
      products = products.where(product_type: params[:product_type]) if params[:product_type].present?
      render json: products
    end

    # GET /api/products/:id
    def show
      render json: Product.find(params[:id])
    end

    # POST /api/products
    def create
      render json: Product.create!(product_params), status: :created
    end

    # PATCH /api/products/:id
    def update
      product = Product.find(params[:id])
      product.update!(product_params)
      render json: product
    end

    # DELETE /api/products/:id
    def destroy
      Product.find(params[:id]).destroy
      head :no_content
    end

    private

    def product_params
      params.permit(
        :name, :code, :category, :product_type,
        :default_price, :currency, :billing_period,
        :description, :is_active,
        metadata: {}
      )
    end
  end
end
