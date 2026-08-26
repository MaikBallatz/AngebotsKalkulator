# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

[
  { name: "Maik Ballatz", email: "maik.ballatz@head-gate.de" },
  { name: "Tim Oldiges", email: "tim.oldiges@head-gate.de" },
  { name: "Sebastian Malies", email: "sebastian.malies@head-gate.de" }
].each do |attrs|
  Consultant.find_or_create_by!(email: attrs[:email]) { |c| c.name = attrs[:name] }
end
