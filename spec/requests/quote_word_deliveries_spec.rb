require "rails_helper"
require "zip"

RSpec.describe "Quote word delivery", type: :request do
  it "emails the consultant a word document with the quote's data filled in" do
    consultant = create(:consultant, name: "Sabine Wagner", email: "sabine.wagner@head-gate.de")
    quote = create(:quote,
      consultant: consultant,
      angebotstyp: "fix",
      company_name: "Musterfirma GmbH",
      position: "Head of Sales",
      minimum_fee: 45_000,
      fee_rate_is_third: true,
      payment_term_days: 10)

    expect {
      post deliver_word_quote_path(quote)
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq(["sabine.wagner@head-gate.de"])
    expect(mail.attachments.length).to eq(1)

    attachment = mail.attachments.first
    zip = Zip::File.open_buffer(attachment.body.raw_source)
    document_xml = zip.read("word/document.xml")

    expect(document_xml).to include("Musterfirma GmbH")
    expect(document_xml).to include("Head of Sales")
    expect(document_xml).to include("ein Drittel")
    expect(document_xml).to include("45000")
    expect(document_xml).to include("10 Tage")
    expect(document_xml).not_to include("{{")
  end
end
