class Deal < ApplicationRecord
  belongs_to :company, optional: true
  has_many :deal_contacts, dependent: :destroy
  has_many :contacts, through: :deal_contacts

  STAGES = %w[prospect qualify demo proposal negotiation closed_won closed_lost].freeze
  LOST_REASONS = %w[price competitor timing no_budget no_decision other].freeze

  validates :title, presence: true
  validates :stage, inclusion: { in: STAGES }
  validates :lost_reason, inclusion: { in: LOST_REASONS }, allow_nil: true
end
