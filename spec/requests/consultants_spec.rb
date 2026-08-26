require "rails_helper"

RSpec.describe "Consultants", type: :request do
  describe "GET /consultants" do
    it "shows the list of consultants" do
      create(:consultant, name: "Anna Berater")
      create(:consultant, name: "Max Mustermann")

      get consultants_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Anna Berater")
      expect(response.body).to include("Max Mustermann")
    end
  end

  describe "POST /consultants" do
    it "adds a new consultant" do
      post consultants_path, params: { consultant: { name: "Petra Neuling", email: "petra.neuling@head-gate.de" } }

      expect(response).to redirect_to(consultants_path)
      follow_redirect!
      expect(response.body).to include("Petra Neuling")
    end
  end

  describe "PATCH /consultants/:id/deactivate" do
    it "marks the consultant as inactive" do
      consultant = create(:consultant, name: "Alte Beraterin", active: true)

      patch deactivate_consultant_path(consultant)

      expect(response).to redirect_to(consultants_path)
      expect(consultant.reload.active).to eq(false)
    end
  end
end
