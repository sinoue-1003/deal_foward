class PlaybookExecution < ApplicationRecord
  belongs_to :playbook
  belongs_to :playbook_step

  STATUSES = %w[completed failed skipped].freeze
  validates :status, inclusion: { in: STATUSES }
end
