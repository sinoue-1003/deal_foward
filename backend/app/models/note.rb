class Note < ApplicationRecord
  belongs_to :tenant
  belongs_to :notable, polymorphic: true
  belongs_to :created_by, class_name: "User", optional: true

  NOTABLE_TYPES = %w[Company Contact Deal Lead Playbook].freeze

  validates :content,      presence: true
  validates :notable_type, inclusion: { in: NOTABLE_TYPES }

  scope :pinned, -> { where(is_pinned: true) }
  scope :recent, -> { order(created_at: :desc) }
end
