FactoryBot.define do
  factory :consultant do
    sequence(:name) { |n| "Berater #{n}" }
    sequence(:email) { |n| "berater#{n}@head-gate.de" }
    active { true }
  end
end
