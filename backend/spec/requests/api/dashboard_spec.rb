require "rails_helper"

RSpec.describe "Api::Dashboard", type: :request do
  describe "GET /api/dashboard/overview" do
    it "returns 200 with dashboard stats" do
      get "/api/dashboard/overview"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include(
        "active_playbooks",
        "total_chat_sessions",
        "total_communications",
        "total_agent_reports",
        "pipeline_value",
        "active_deals"
      )
    end

    it "counts active playbooks correctly" do
      create(:playbook, status: "active")
      create(:playbook, status: "active")
      create(:playbook, status: "completed")

      get "/api/dashboard/overview"
      json = JSON.parse(response.body)
      expect(json["active_playbooks"]).to be >= 2
    end
  end

  describe "GET /api/dashboard/pipeline" do
    it "returns 200 with pipeline data" do
      get "/api/dashboard/pipeline"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/dashboard/agent_activity" do
    it "returns 200 with agent activity data" do
      get "/api/dashboard/agent_activity"
      expect(response).to have_http_status(:ok)
    end
  end
end
