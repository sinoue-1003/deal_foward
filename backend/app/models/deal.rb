class Deal < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true

  has_many :deal_contacts, dependent: :destroy
  has_many :contacts, through: :deal_contacts
  has_many :playbooks
  has_many :communications
  has_many :agent_reports
  has_many :agent_runs
  has_many :tasks

  STAGES             = %w[prospect qualify demo proposal negotiation closed_won closed_lost].freeze
  SOURCES            = %w[inbound outbound referral partner event web other].freeze
  DEAL_TYPES         = %w[new_business expansion renewal upsell cross_sell].freeze
  FORECAST_CATEGORIES = %w[commit best_case pipeline omitted].freeze

  enum :lost_reason, {
    price:       "price",
    competitor:  "competitor",
    timing:      "timing",
    no_budget:   "no_budget",
    no_decision: "no_decision",
    other:       "other"
  }

  validates :title,             presence: true
  validates :stage,             inclusion: { in: STAGES }
  validates :deal_type,         inclusion: { in: DEAL_TYPES },          allow_nil: true
  validates :source,            inclusion: { in: SOURCES },             allow_nil: true
  validates :forecast_category, inclusion: { in: FORECAST_CATEGORIES }, allow_nil: true
  validates :probability,       numericality: { in: 0..100 },           allow_nil: true
  validates :budget,            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :amount,            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
