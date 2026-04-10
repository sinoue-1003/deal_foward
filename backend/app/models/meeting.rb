class Meeting < ApplicationRecord
  belongs_to :tenant
  belongs_to :deal,    optional: true
  belongs_to :company, optional: true

  has_many :attendees, class_name: "MeetingAttendee", dependent: :destroy
  has_many :contacts, through: :attendees
  has_one  :insight,  class_name: "MeetingInsight",  dependent: :destroy

  MEETING_TYPES = %w[discovery demo proposal negotiation kickoff qbr other].freeze
  STATUSES      = %w[scheduled in_progress completed cancelled no_show].freeze

  validates :title,        presence: true
  validates :meeting_type, inclusion: { in: MEETING_TYPES }
  validates :status,       inclusion: { in: STATUSES }

  scope :completed, -> { where(status: "completed") }
  scope :upcoming,  -> { where(status: "scheduled").where("started_at > ?", Time.current) }

  def duration_from_timestamps
    return nil unless started_at && ended_at
    ((ended_at - started_at) / 60).round
  end
end
