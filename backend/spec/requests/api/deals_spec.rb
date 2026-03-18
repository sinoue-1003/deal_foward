require "rails_helper"

RSpec.describe "Api::Deals", type: :request do
  let!(:company) { create(:company) }
  let!(:deal) { create(:deal, company: company) }

  describe "GET /api/deals" do
    it "returns 200 with a list of deals" do
      get "/api/deals"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.length).to be >= 1
    end

    it "filters by stage" do
      prospect_deal = create(:deal, company: company, stage: "prospect")
      create(:deal, company: company, stage: "qualify")

      get "/api/deals", params: { stage: "prospect" }
      json = JSON.parse(response.body)
      stages = json.map { |d| d["stage"] }.uniq
      expect(stages).to eq([ "prospect" ])
    end
  end

  describe "GET /api/deals/:id" do
    it "returns the deal with details" do
      get "/api/deals/#{deal.id}"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(deal.id)
      expect(json["title"]).to eq(deal.title)
    end

    it "returns 404 for unknown id" do
      get "/api/deals/00000000-0000-0000-0000-000000000000"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/deals" do
    it "creates a deal and returns 201" do
      post "/api/deals", params: {
        title: "New Deal",
        company_id: company.id,
        stage: "prospect",
        amount: 50000
      }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("New Deal")
      expect(json["stage"]).to eq("prospect")
    end

    it "returns 400 when title is missing" do
      post "/api/deals", params: { company_id: company.id, stage: "prospect" }
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:bad_request)
    end
  end

  describe "PATCH /api/deals/:id" do
    it "updates the deal" do
      patch "/api/deals/#{deal.id}", params: { stage: "qualify", title: deal.title }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["stage"]).to eq("qualify")
    end
  end

  describe "DELETE /api/deals/:id" do
    it "deletes the deal and returns 204" do
      delete "/api/deals/#{deal.id}"
      expect(response).to have_http_status(:no_content)
      expect(Deal.find_by(id: deal.id)).to be_nil
    end
  end
end
