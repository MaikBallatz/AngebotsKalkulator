require "rails_helper"

RSpec.describe "Quote upload", type: :request do
  it "converts the uploaded word document to pdf and emails it back" do
    quote = create(:quote, consultant: create(:consultant, email: "sabine.wagner@head-gate.de"))
    file = fixture_file_upload(Rails.root.join("lib/word_templates/fix.docx"), "application/vnd.openxmlformats-officedocument.wordprocessingml.document")

    expect {
      post upload_quote_path(quote), params: { signed_document: file }
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    expect(response).to redirect_to(quote_path(quote))

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq(["sabine.wagner@head-gate.de"])
    expect(mail.attachments.length).to eq(1)
    expect(mail.attachments.first.content_type).to include("application/pdf")
  end
end
