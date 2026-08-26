FactoryBot.define do
  factory :quote do
    association :consultant
    angebotstyp { "fix" }
    company_name { "Musterfirma GmbH" }
    contact_person { "Herr Schmidt" }
    address { "Musterstraße 1\n12345 Musterstadt" }
    phone { "0123 456789" }
    position { "Head of Sales" }
    project_reference { "ES-2026-042" }
    minimum_fee { 45_000 }
    fee_rate_is_third { true }
    payment_term_days { 10 }
  end
end
