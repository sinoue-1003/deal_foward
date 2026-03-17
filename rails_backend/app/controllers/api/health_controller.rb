module Api
  class HealthController < BaseController
    def show
      render json: { status: "ok", version: "2.0.0", service: "Deal Forward API" }
    end
  end
end
