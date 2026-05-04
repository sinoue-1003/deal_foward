class Sequence < ApplicationRecord
  belongs_to :tenant
  belongs_to :created_by, class_name: "User", optional: true

  has_many :steps,       class_name: "SequenceStep",       dependent: :destroy
  has_many :enrollments, class_name: "SequenceEnrollment", dependent: :destroy
  has_many :contacts, through: :enrollments

  STATUSES        = %w[active paused archived].freeze
  SEQUENCE_TYPES  = %w[outbound inbound nurture onboarding renewal].freeze

  validates :name,          presence: true
  validates :status,        inclusion: { in: STATUSES }
  validates :sequence_type, inclusion: { in: SEQUENCE_TYPES }, allow_nil: true

  scope :active, -> { where(status: "active") }

  def enroll!(contact, deal: nil, enrolled_by: nil)
    enrollments.create!(
      tenant:            tenant,
      contact:           contact,
      deal:              deal,
      enrolled_by:       enrolled_by,
      current_step_index: 0
    )
  end
end
