class EmailMessage < ApplicationRecord
  belongs_to :tenant
  belongs_to :contact,             optional: true
  belongs_to :deal,                optional: true
  belongs_to :company,             optional: true
  belongs_to :sequence_enrollment, optional: true

  STATUSES    = %w[draft sent delivered opened clicked replied bounced spam].freeze
  DIRECTIONS  = %w[inbound outbound].freeze

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :status,    inclusion: { in: STATUSES }

  scope :outbound, -> { where(direction: "outbound") }
  scope :inbound,  -> { where(direction: "inbound") }
  scope :opened,   -> { where.not(opened_at: nil) }
  scope :replied,  -> { where.not(replied_at: nil) }

  def open_rate_eligible?
    status.in?(%w[sent delivered opened clicked replied])
  end
end
