class AgentReport < ApplicationRecord
  belongs_to :tenant
  belongs_to :company,  optional: true
  belongs_to :contact,  optional: true
  belongs_to :deal,     optional: true
  belongs_to :playbook, optional: true

  REPORT_TYPES = %w[activity analysis recommendation alert].freeze
  STATUSES     = %w[pending in_progress completed].freeze

  validates :action_taken,     presence: true
  validates :report_type,      inclusion: { in: REPORT_TYPES }, allow_nil: true
  validates :status,           inclusion: { in: STATUSES }
  validates :confidence_score, numericality: { in: 0..100 },    allow_nil: true
end
