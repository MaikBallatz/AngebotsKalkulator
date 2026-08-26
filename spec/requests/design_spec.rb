require "rails_helper"

RSpec.describe "Design", type: :request do
  it "renders the design system page" do
    get "/design"
    expect(response).to have_http_status(:ok)
  end
end
