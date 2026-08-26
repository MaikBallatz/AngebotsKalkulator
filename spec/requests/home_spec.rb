require "rails_helper"

RSpec.describe "Home", type: :request do
  it "shows the app name" do
    get root_path
    expect(response).to have_http_status(:ok)
  end
end
