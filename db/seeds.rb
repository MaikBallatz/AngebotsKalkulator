# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

[
  { name: "Ralf Klein", email: "ralf.klein@head-gate.de" },
  { name: "Sabine Wagner", email: "sabine.wagner@head-gate.de" },
  { name: "Michael Ballatz", email: "michael.ballatz@head-gate.de" }
].each do |attrs|
  Consultant.find_or_create_by!(email: attrs[:email]) { |c| c.name = attrs[:name] }
end
