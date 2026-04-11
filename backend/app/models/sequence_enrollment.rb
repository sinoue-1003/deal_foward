class SequenceEnrollment < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :sequence
  belongs_to :contact
  belongs_to :deal,        optional: true
  belongs_to :enrolled_by, class_name: "User", optional: true

  has_many :email_messages, dependent: :nullify

  has_many :sales_events, -> { where(aggregate_type: "SequenceEnrollment") },
           foreign_key: :aggregate_id, primary_key: :id

  STATUSES = %w[active paused completed replied opted_out bounced].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :active,    -> { where(status: "active") }
  scope :terminal,  -> { where(status: %w[completed replied opted_out bounced]) }

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create :emit_enrolled
  after_update :emit_status_event, if: :saved_change_to_status?

  def advance_step!
    next_idx = current_step_index + 1
    if next_idx >= sequence.steps.count
      update!(status: "completed", completed_at: Time.current)
    else
      update!(current_step_index: next_idx)
    end
  end

  private

  def emit_enrolled
    publish_event!("sequence.enrolled", payload: {
      sequence_id: sequence_id,
      contact_id:  contact_id,
      deal_id:     deal_id
    })
  end

  def emit_status_event
    _prev, curr = saved_change_to_status
    event_type = case curr
                 when "completed" then "sequence.completed"
                 when "replied"   then "sequence.replied"
                 when "opted_out" then "sequence.opted_out"
                 end
    publish_event!(event_type, payload: {
      sequence_id: sequence_id,
      contact_id:  contact_id,
      deal_id:     deal_id
    }) if event_type
  end
end
