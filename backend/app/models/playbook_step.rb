class PlaybookStep < ApplicationRecord
  belongs_to :tenant
  belongs_to :playbook
  has_many :playbook_executions, dependent: :destroy
  has_many :tasks, dependent: :nullify

  STATUSES       = %w[pending in_progress completed failed skipped].freeze
  EXECUTOR_TYPES = %w[ai human customer].freeze
  ACTION_TYPES   = %w[
    send_slack_message  schedule_meeting    send_email
    update_crm          create_followup_task send_proposal
    request_demo        share_case_study    follow_up_call
    wait_customer_response
  ].freeze

  validates :step_index,    presence: true
  validates :action_type,   inclusion: { in: ACTION_TYPES }
  validates :executor_type, inclusion: { in: EXECUTOR_TYPES }
  validates :status,        inclusion: { in: STATUSES }

  default_scope { order(:step_index) }

  def pending?   = status == "pending"
  def terminal?  = %w[completed skipped failed].include?(status)

  def approvable?
    approval_required? && approved_at.nil? && status == "pending"
  end
end
