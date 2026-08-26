class QuoteMailer < ApplicationMailer
  def word_document(quote, document)
    @quote = quote

    attachments["#{quote.company_name}.docx"] = {
      mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      content: document
    }

    mail(to: quote.consultant.email, subject: "Angebot #{quote.company_name} – bitte prüfen und unterschreiben")
  end
end
