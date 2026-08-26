require "tmpdir"

# Converts a Word document (as binary content) to PDF via a headless
# LibreOffice, which must be installed on the machine (`soffice` on PATH).
class QuoteDocumentToPdfConverter
  def initialize(docx_content)
    @docx_content = docx_content
  end

  def call
    Dir.mktmpdir do |dir|
      docx_path = File.join(dir, "document.docx")
      File.binwrite(docx_path, docx_content)

      system("soffice", "--headless", "--convert-to", "pdf", "--outdir", dir, docx_path, exception: true)

      File.binread(File.join(dir, "document.pdf"))
    end
  end

  private

  attr_reader :docx_content
end
