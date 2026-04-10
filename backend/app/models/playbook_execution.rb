class PlaybookExecution < ApplicationRecord
  belongs_to :tenant
  belongs_to :playbook
  belongs_to :playbook_step
  belongs_to :executed_by, class_name: "User", optional: true

  STATUSES = %w[completed failed skipped].freeze
  validates :status, inclusion: { in: STATUSES }
end
