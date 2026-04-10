class SequenceEnrollment < ApplicationRecord
  belongs_to :tenant
  belongs_to :sequence
  belongs_to :contact
  belongs_to :deal,        optional: true
  belongs_to :enrolled_by, class_name: "User", optional: true

  has_many :email_messages, dependent: :nullify

  STATUSES = %w[active paused completed replied opted_out bounced].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :active,    -> { where(status: "active") }
  scope :terminal,  -> { where(status: %w[completed replied opted_out bounced]) }

  def advance_step!
    next_idx = current_step_index + 1
    if next_idx >= sequence.steps.count
      update!(status: "completed", completed_at: Time.current)
    else
      update!(current_step_index: next_idx)
    end
  end
end
