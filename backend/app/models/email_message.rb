class EmailMessage < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :contact,             optional: true
  belongs_to :deal,                optional: true
  belongs_to :company,             optional: true
  belongs_to :sequence_enrollment, optional: true

  has_many :sales_events, -> { where(aggregate_type: "EmailMessage") },
           foreign_key: :aggregate_id, primary_key: :id

  STATUSES    = %w[draft sent delivered opened clicked replied bounced spam].freeze
  DIRECTIONS  = %w[inbound outbound].freeze

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :status,    inclusion: { in: STATUSES }

  scope :outbound, -> { where(direction: "outbound") }
  scope :inbound,  -> { where(direction: "inbound") }
  scope :opened,   -> { where.not(opened_at: nil) }
  scope :replied,  -> { where.not(replied_at: nil) }

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create :emit_email_sent, if: -> { direction == "outbound" && status == "sent" }
  after_update :emit_status_event, if: :saved_change_to_status?

  def open_rate_eligible?
    status.in?(%w[sent delivered opened clicked replied])
  end

  private

  def emit_email_sent
    publish_event!("email.sent", payload: {
      deal_id:               deal_id,
      contact_id:            contact_id,
      sequence_enrollment_id: sequence_enrollment_id
    })
  end

  def emit_status_event
    _prev, curr = saved_change_to_status
    event_type = case curr
                 when "opened"  then "email.opened"
                 when "replied" then "email.replied"
                 when "bounced" then "email.bounced"
                 end
    publish_event!(event_type, payload: {
      deal_id:    deal_id,
      contact_id: contact_id
    }) if event_type
  end
end
