class AgentRun < ApplicationRecord
  belongs_to :tenant
  belongs_to :company,  optional: true
  belongs_to :playbook, optional: true
  belongs_to :contact,  optional: true
  belongs_to :deal,     optional: true

  STATUSES   = %w[analyzing executing waiting_approval reporting completed failed].freeze
  TRIGGERS   = %w[manual high_intent scheduled].freeze
  RUN_TYPES  = %w[analysis execution monitoring reporting].freeze

  validates :status,   inclusion: { in: STATUSES }
  validates :trigger,  inclusion: { in: TRIGGERS }
  validates :run_type, inclusion: { in: RUN_TYPES }, allow_nil: true

  scope :active,   -> { where(status: %w[analyzing executing waiting_approval reporting]) }
  scope :terminal, -> { where(status: %w[completed failed]) }
  scope :recent,   -> { order(created_at: :desc) }
end
