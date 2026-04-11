class PlaybookStep < ApplicationRecord
  belongs_to :tenant
  belongs_to :playbook
  belongs_to :executed_by, class_name: "User", optional: true

  has_many :playbook_executions, dependent: :destroy
  has_many :tasks,               dependent: :nullify

  STATUSES       = %w[pending in_progress completed failed skipped].freeze
  EXECUTOR_TYPES = %w[ai human customer].freeze
  ACTION_TYPES   = %w[
    send_slack_message   schedule_meeting     send_email
    update_crm           create_followup_task send_proposal
    request_demo         share_case_study     follow_up_call
    wait_customer_response
  ].freeze

  validates :step_index,    presence: true
  validates :action_type,   inclusion: { in: ACTION_TYPES }
  validates :executor_type, inclusion: { in: EXECUTOR_TYPES }
  validates :status,        inclusion: { in: STATUSES }

  default_scope { order(:step_index) }

  # ── イベント発行（集約はPlaybook）──────────────────────────────────
  after_update :emit_step_status_event, if: :saved_change_to_status?

  def pending?   = status == "pending"
  def terminal?  = %w[completed skipped failed].include?(status)

  def approvable?
    approval_required? && approved_at.nil? && status == "pending"
  end

  private

  def emit_step_status_event
    _prev, curr = saved_change_to_status
    return unless curr.in?(%w[completed skipped failed])

    # ステップ完了イベントはPlaybook集約に対して発行（集約ルートはPlaybook）
    SalesEvent.publish!(
      tenant:      tenant,
      event_type:  "playbook.step_completed",
      aggregate:   playbook,
      payload: {
        step_index:    step_index,
        action_type:   action_type,
        executor_type: executor_type,
        status:        curr
      }
    )
  end
end
