class MeetingAttendee < ApplicationRecord
  belongs_to :tenant
  belongs_to :meeting
  belongs_to :contact, optional: true
  belongs_to :user,    optional: true

  ATTENDEE_TYPES = %w[internal external].freeze

  validates :attendee_type, inclusion: { in: ATTENDEE_TYPES }
  validate  :contact_or_user_or_name_present

  def display_name
    contact&.full_name || user&.name || name
  end

  private

  def contact_or_user_or_name_present
    unless contact_id.present? || user_id.present? || name.present?
      errors.add(:base, "contact, user, または name のいずれかが必要です")
    end
  end
end
