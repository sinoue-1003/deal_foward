class Task < ApplicationRecord
  belongs_to :tenant
  belongs_to :deal,          optional: true
  belongs_to :company,       optional: true
  belongs_to :contact,       optional: true
  belongs_to :playbook_step, optional: true
  belongs_to :assigned_to,   class_name: "User", optional: true

  TASK_TYPES = %w[call email meeting demo proposal follow_up other].freeze
  STATUSES   = %w[pending in_progress completed cancelled].freeze
  PRIORITIES = %w[high medium low].freeze

  validates :title,     presence: true
  validates :task_type, inclusion: { in: TASK_TYPES }
  validates :status,    inclusion: { in: STATUSES }
  validates :priority,  inclusion: { in: PRIORITIES }

  scope :open,      -> { where(status: %w[pending in_progress]) }
  scope :overdue,   -> { open.where("due_at < ?", Time.current) }
  scope :due_today, -> { open.where(due_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :recent,    -> { order(created_at: :desc) }
end
