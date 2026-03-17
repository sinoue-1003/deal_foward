module AgentAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_agent!
  end

  private

  def authenticate_agent!
    api_key = request.headers["X-Agent-Api-Key"]
    render json: { error: "Unauthorized" }, status: :unauthorized unless api_key == ENV["AGENT_API_KEY"]
  end
end
