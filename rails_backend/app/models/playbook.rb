class Playbook < ApplicationRecord
  belongs_to :company, optional: true
  belongs_to :contact, optional: true
  has_many :playbook_executions, dependent: :destroy

  STATUSES = %w[active paused completed].freeze
  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Returns current step info for AI and human to share
  def current_step_info
    return nil if steps.blank?
    steps[current_step]
  end

  # Returns next pending step
  def next_action
    steps.find { |s| s["status"] == "pending" }
  end

  # Auto-complete the playbook when all steps are in a terminal state
  def maybe_auto_complete!
    terminal = %w[completed skipped failed]
    return if steps.blank?
    update!(status: "completed") if steps.all? { |s| terminal.include?(s["status"]) }
  end

  # Summary of current situation and next actions for shared AI+human context
  def status_summary
    completed = steps.count { |s| s["status"] == "completed" }
    total = steps.size
    next_act = next_action

    {
      situation: situation_summary,
      progress: "#{completed}/#{total}ステップ完了",
      current_step: current_step,
      next_action: next_act ? {
        step: next_act["step"],
        action_type: next_act["action_type"],
        channel: next_act["channel"],
        description: next_act["template"]
      } : nil,
      status: status
    }
  end
end
