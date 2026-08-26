# Shared, non-user-owned model: AngebotsPilot has no login (see CLAUDE.md, Part 1).
# Every quote is visible to everyone; there is no per-user scoping to apply here.
class Quote < ApplicationRecord
  belongs_to :consultant
  has_one_attached :signed_document

  enum :angebotstyp, { fix: "fix", variable: "variable", englisch: "englisch", volumelimit: "volumelimit" }

  validates :company_name, presence: true
  validates :contact_person, presence: true
  validates :position, presence: true
  validates :minimum_fee, presence: true
  validates :payment_term_days, presence: true
  validates :volume_limit, presence: true, if: :volumelimit?
end
