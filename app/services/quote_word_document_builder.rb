# Fills a quote's Word template with the quote's data.
# Templates live in lib/word_templates/*.docx with {{TOKEN}} placeholders
# already isolated into single runs — see the increment history for how they
# were prepared.
class QuoteWordDocumentBuilder
  TEMPLATES = {
    "fix" => Rails.root.join("lib/word_templates/fix.docx"),
    "variable" => Rails.root.join("lib/word_templates/variable.docx"),
    "englisch" => Rails.root.join("lib/word_templates/englisch.docx"),
    "volumelimit" => Rails.root.join("lib/word_templates/volumelimit.docx")
  }.freeze

  def initialize(quote)
    @quote = quote
  end

  def call
    template_path = TEMPLATES.fetch(quote.angebotstyp)
    buffer = File.binread(template_path)

    Zip::OutputStream.write_buffer do |out|
      Zip::File.open_buffer(buffer) do |zip|
        zip.each do |entry|
          content = entry.get_input_stream.read
          content = replace_tokens(content.dup.force_encoding("UTF-8")) if entry.name == "word/document.xml"
          out.put_next_entry(entry.name)
          out.write(content)
        end
      end
    end.string
  end

  private

  attr_reader :quote

  def replace_tokens(xml)
    tokens.reduce(xml) { |text, (token, value)| text.gsub(token, value) }
  end

  def tokens
    address_lines = quote.address.to_s.split("\n")

    {
      "{{COMPANY_NAME}}" => quote.company_name,
      "{{COMPANY_ADDRESS_LINE1}}" => address_lines[0].to_s,
      "{{COMPANY_ADDRESS_LINE2}}" => address_lines[1].to_s,
      "{{COMPANY_PHONE}}" => quote.phone.to_s,
      "{{CONTACT_PERSON}}" => quote.contact_person,
      "{{CONSULTANT_NAME}}" => quote.consultant.name,
      "{{POSITION}}" => quote.position,
      "{{PROJECT_REFERENCE}}" => quote.project_reference.to_s,
      "{{FEE_RATE_TEXT}}" => fee_rate_text,
      "{{MINIMUM_FEE}}" => quote.minimum_fee.to_i.to_s,
      "{{PAYMENT_TERM_DAYS}}" => quote.payment_term_days.to_s,
      "{{VOLUME_LIMIT}}" => quote.volume_limit.to_s,
      "{{DATE}}" => Date.current.strftime("%d.%m.%Y")
    }
  end

  def fee_rate_text
    if quote.fee_rate_is_third?
      quote.englisch? ? "one third" : "ein Drittel"
    else
      "#{quote.fee_rate_percentage.to_s.sub(/\.0\z/, "")} %"
    end
  end
end
