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
end
