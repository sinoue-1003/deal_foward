class Playbook < ApplicationRecord
  belongs_to :company, optional: true
  belongs_to :contact, optional: true
  has_many :playbook_steps, -> { order(:step_index) }, dependent: :destroy
  has_many :playbook_executions, dependent: :destroy

  STATUSES = %w[active paused completed].freeze
  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }

  # 次のpendingステップを返す
  def next_action
    playbook_steps.find_by(status: "pending")
  end

  # 全ステップが終端状態になったら自動完了
  def maybe_auto_complete!
    return if playbook_steps.empty?
    update!(status: "completed") if playbook_steps.reload.all?(&:terminal?)
  end

  # AIと人間が共有する状況サマリー
  def status_summary
    steps = playbook_steps.to_a
    total = steps.size
    completed = steps.count { |s| s.status == "completed" }
    next_act = next_action

    {
      situation: situation_summary,
      progress: "#{completed}/#{total}ステップ完了",
      next_action: next_act ? {
        step: next_act.step_index,
        action_type: next_act.action_type,
        executor_type: next_act.executor_type,
        channel: next_act.channel,
        description: next_act.template
      } : nil,
      status: status
    }
  end
end
