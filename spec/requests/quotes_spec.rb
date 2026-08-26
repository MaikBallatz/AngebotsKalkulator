require "rails_helper"

RSpec.describe "Quotes", type: :request do
  describe "POST /quotes" do
    it "creates a quote with the entered eckdaten" do
      consultant = create(:consultant, name: "Sabine Wagner")

      post quotes_path, params: {
        quote: {
          angebotstyp: "fix",
          consultant_id: consultant.id,
          company_name: "Musterfirma GmbH",
          contact_person: "Herr Schmidt",
          address: "Musterstraße 1\n12345 Musterstadt",
          position: "Head of Sales",
          project_reference: "ES-2026-042",
          minimum_fee: "45000",
          fee_rate_is_third: "1",
          payment_term_days: "10"
        }
      }

      expect(response).to have_http_status(:redirect)
      follow_redirect!

      expect(response.body).to include("Musterfirma GmbH")
      expect(response.body).to include("Head of Sales")
      expect(response.body).to include("ES-2026-042")
      expect(response.body).to include("Sabine Wagner")
    end

    it "saves the volume limit for the Volume-Limit type" do
      consultant = create(:consultant)

      post quotes_path, params: {
        quote: {
          angebotstyp: "volumelimit",
          consultant_id: consultant.id,
          company_name: "Musterfirma GmbH",
          contact_person: "Herr Schmidt",
          position: "Head of Sales",
          minimum_fee: "45000",
          fee_rate_is_third: "1",
          payment_term_days: "10",
          volume_limit: "120"
        }
      }

      follow_redirect!
      expect(response.body).to include("120 Zielpersonen")
    end
  end
end
