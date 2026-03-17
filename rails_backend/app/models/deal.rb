class Deal < ApplicationRecord
  belongs_to :company, optional: true
  belongs_to :contact, optional: true

  STAGES = %w[prospect qualify demo proposal negotiation closed_won closed_lost].freeze
  validates :title, presence: true
  validates :stage, inclusion: { in: STAGES }
end
