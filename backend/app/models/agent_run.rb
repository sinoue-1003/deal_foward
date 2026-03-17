class AgentRun < ApplicationRecord
  belongs_to :company,  optional: true
  belongs_to :playbook, optional: true

  STATUSES = %w[analyzing executing waiting_approval reporting completed failed].freeze
  TRIGGERS = %w[manual high_intent scheduled].freeze

  validates :status,  inclusion: { in: STATUSES }
  validates :trigger, inclusion: { in: TRIGGERS }

  scope :active,   -> { where(status: %w[analyzing executing waiting_approval reporting]) }
  scope :terminal, -> { where(status: %w[completed failed]) }
  scope :recent,   -> { order(created_at: :desc) }
end
