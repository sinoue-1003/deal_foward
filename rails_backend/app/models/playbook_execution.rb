class PlaybookExecution < ApplicationRecord
  belongs_to :playbook

  STATUSES = %w[pending in_progress completed failed skipped].freeze
  validates :step_index, presence: true
  validates :status, inclusion: { in: STATUSES }
end
