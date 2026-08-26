require "rails_helper"

RSpec.describe "Flow", type: :request do
  it "renders the workflow page while requirements are still empty" do
    get "/flow"
    expect(response).to have_http_status(:ok)
  end
end
