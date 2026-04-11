class Playbook < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :company, optional: true
  belongs_to :contact, optional: true
  belongs_to :deal,    optional: true

  has_many :playbook_steps, -> { order(:step_index) }, dependent: :destroy
  has_many :playbook_executions, dependent: :destroy
  has_many :agent_reports
  has_many :sales_events, -> { where(aggregate_type: "Playbook") },
           foreign_key: :aggregate_id, primary_key: :id

  STATUSES   = %w[active paused completed].freeze
  PRIORITIES = %w[high medium low].freeze

  validates :title,    presence: true
  validates :status,   inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }, allow_nil: true

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create :emit_playbook_created
  after_update :emit_field_changes
  after_update :emit_status_event, if: :saved_change_to_status?

  # 次のpendingステップを返す（controller/agent から呼ばれる）
  def next_action
    playbook_steps.find_by(status: "pending")
  end

  # 全ステップが終端状態になったら自動完了
  def maybe_auto_complete!
    return if playbook_steps.empty?
    if playbook_steps.reload.all?(&:terminal?)
      update!(status: "completed", completed_at: Time.current)
    end
  end

  # AIと人間が共有する状況サマリー
  def status_summary
    steps     = playbook_steps.to_a
    total     = steps.size
    completed = steps.count { |s| s.status == "completed" }
    nxt       = next_action

    {
      situation:   situation_summary,
      priority:    priority,
      progress:    "#{completed}/#{total}ステップ完了",
      next_action: nxt ? {
        step:              nxt.step_index,
        action_type:       nxt.action_type,
        executor_type:     nxt.executor_type,
        channel:           nxt.channel,
        description:       nxt.description || nxt.template,
        approval_required: nxt.approval_required
      } : nil,
      status:   status,
      due_date: due_date
    }
  end

  private

  def emit_playbook_created
    publish_event!("playbook.created", payload: {
      deal_id:    deal_id,
      company_id: company_id,
      title:      title
    })
  end

  def emit_status_event
    _prev, curr = saved_change_to_status
    publish_event!("playbook.completed", payload: {
      deal_id:    deal_id,
      company_id: company_id
    }) if curr == "completed"
  end
end
