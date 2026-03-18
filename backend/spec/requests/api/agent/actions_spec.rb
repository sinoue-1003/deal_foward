require "rails_helper"

RSpec.describe "Api::Agent::Actions", type: :request do
  let!(:company) { create(:company) }

  describe "authentication" do
    it "returns 401 without agent API key" do
      get "/api/agent/communications"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with wrong API key" do
      get "/api/agent/communications", headers: { "X-Agent-Api-Key" => "wrong-key" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "allows access with valid API key" do
      get "/api/agent/communications", headers: agent_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/agent/communications" do
    let!(:comm) { create(:communication, company: company) }

    it "returns communications list" do
      get "/api/agent/communications", headers: agent_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end

    it "filters by company_id" do
      other_company = create(:company)
      create(:communication, company: other_company)

      get "/api/agent/communications", params: { company_id: company.id }, headers: agent_headers
      json = JSON.parse(response.body)
      company_ids = json.map { |c| c["company_id"] }.compact.uniq
      expect(company_ids).to all(eq(company.id))
    end
  end

  describe "POST /api/agent/report" do
    it "creates a report and returns 201" do
      allow_any_instance_of(WebhookNotifierService).to receive(:notify)
      allow(WebhookNotifierService).to receive(:notify)

      post "/api/agent/report",
        params: {
          company_id: company.id,
          action_taken: "Sent follow-up email",
          status: "completed"
        },
        headers: agent_headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["action_taken"]).to eq("Sent follow-up email")
    end

    it "returns 400 when action_taken is missing" do
      post "/api/agent/report",
        params: { company_id: company.id },
        headers: agent_headers
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/agent/request_context" do
    it "returns company context" do
      post "/api/agent/request_context",
        params: { company_id: company.id },
        headers: agent_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include("company", "contacts", "recent_communications")
    end

    it "returns error when company_id is missing" do
      post "/api/agent/request_context", headers: agent_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["error"]).to be_present
    end
  end

  describe "GET /api/agent/contacts/:company_id" do
    let!(:contact) { create(:contact, company: company) }

    it "returns contacts for the company" do
      get "/api/agent/contacts/#{company.id}", headers: agent_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.first["id"]).to eq(contact.id)
    end
  end

  describe "GET /api/agent/playbook/:id" do
    let!(:playbook) { create(:playbook, company: company) }

    it "returns playbook with status_summary" do
      get "/api/agent/playbook/#{playbook.id}", headers: agent_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(playbook.id)
      expect(json["status_summary"]).to be_present
    end
  end

  describe "PATCH /api/agent/playbook/:id/step/:step_index" do
    let!(:playbook) { create(:playbook, company: company) }
    let!(:step) { create(:playbook_step, playbook: playbook, step_index: 0, status: "pending") }

    it "updates the step status" do
      patch "/api/agent/playbook/#{playbook.id}/step/0",
        params: {
          status: "completed",
          action_content: "Email sent successfully",
          result: "Customer replied positively"
        },
        headers: agent_headers

      expect(response).to have_http_status(:ok)
      expect(step.reload.status).to eq("completed")
    end

    it "returns 404 for unknown step_index" do
      patch "/api/agent/playbook/#{playbook.id}/step/999",
        params: { status: "completed" },
        headers: agent_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
