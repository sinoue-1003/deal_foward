class Deal < ApplicationRecord
  belongs_to :company, optional: true
  has_many :deal_contacts, dependent: :destroy
  has_many :contacts, through: :deal_contacts

  STAGES = %w[prospect qualify demo proposal negotiation closed_won closed_lost].freeze

  enum :lost_reason, {
    price: "price",
    competitor: "competitor",
    timing: "timing",
    no_budget: "no_budget",
    no_decision: "no_decision",
    other: "other"
  }

  validates :title, presence: true
  validates :stage, inclusion: { in: STAGES }
end
