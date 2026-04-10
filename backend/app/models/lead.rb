class Lead < ApplicationRecord
  belongs_to :tenant
  belongs_to :assigned_to,          class_name: "User",    optional: true
  belongs_to :converted_to_contact, class_name: "Contact", optional: true
  belongs_to :converted_to_deal,    class_name: "Deal",    optional: true

  has_many :notes, as: :notable, dependent: :destroy

  STATUSES = %w[new working converted disqualified].freeze
  SOURCES  = %w[inbound_form chat referral cold_outreach event partner web other].freeze

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :status,     inclusion: { in: STATUSES }
  validates :source,     inclusion: { in: SOURCES }, allow_nil: true
  validates :score,      numericality: { in: 0..100 }, allow_nil: true

  scope :open,        -> { where(status: %w[new working]) }
  scope :converted,   -> { where(status: "converted") }
  scope :hot,         -> { where("score >= 80") }

  def full_name
    "#{last_name} #{first_name}".strip
  end

  def convert!(contact:, deal: nil)
    update!(
      status:               "converted",
      converted_to_contact: contact,
      converted_to_deal:    deal,
      converted_at:         Time.current
    )
  end
end
