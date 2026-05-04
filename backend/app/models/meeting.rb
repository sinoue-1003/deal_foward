class Meeting < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :deal,          optional: true
  belongs_to :company,       optional: true
  belongs_to :communication, optional: true  # Zoom録画インポート元

  has_many :attendees, class_name: "MeetingAttendee", dependent: :destroy
  has_many :contacts, through: :attendees
  has_one  :insight,  class_name: "MeetingInsight",  dependent: :destroy

  has_many :sales_events, -> { where(aggregate_type: "Meeting") },
           foreign_key: :aggregate_id, primary_key: :id

  MEETING_TYPES = %w[discovery demo proposal negotiation kickoff qbr other].freeze
  STATUSES      = %w[scheduled in_progress completed cancelled no_show].freeze

  validates :title,        presence: true
  validates :meeting_type, inclusion: { in: MEETING_TYPES }
  validates :status,       inclusion: { in: STATUSES }

  scope :completed, -> { where(status: "completed") }
  scope :upcoming,  -> { where(status: "scheduled").where("started_at > ?", Time.current) }

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create :emit_meeting_scheduled
  after_update :emit_field_changes                                    # 全フィールド差分
  after_update :emit_status_event, if: :saved_change_to_status?

  def duration_from_timestamps
    return nil unless started_at && ended_at
    ((ended_at - started_at) / 60).round
  end

  private

  def emit_meeting_scheduled
    publish_event!("meeting.scheduled", payload: {
      deal_id:      deal_id,
      meeting_type: meeting_type,
      started_at:   started_at
    })
  end

  def emit_status_event
    _prev, curr = saved_change_to_status
    event_type = case curr
                 when "completed" then "meeting.completed"
                 when "no_show"   then "meeting.no_show"
                 when "cancelled" then "meeting.cancelled"
                 end
    publish_event!(event_type, payload: {
      deal_id:      deal_id,
      meeting_type: meeting_type,
      duration_min: duration_from_timestamps
    }) if event_type
  end
end
