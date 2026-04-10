class Quote < ApplicationRecord
  belongs_to :tenant
  belongs_to :deal,        optional: true
  belongs_to :contact,     optional: true
  belongs_to :created_by,  class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true

  has_many :line_items, class_name: "QuoteLineItem", dependent: :destroy
  has_many :products, through: :line_items
  has_one  :contract, dependent: :nullify

  STATUSES = %w[draft sent viewed accepted rejected expired].freeze

  validates :quote_number, presence: true, uniqueness: { scope: :tenant_id }
  validates :status,       inclusion: { in: STATUSES }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :generate_quote_number, on: :create
  before_save :recalculate_totals

  scope :active, -> { where(status: %w[draft sent viewed]) }

  def recalculate_totals
    self.subtotal        = line_items.sum(&:total_price) || 0
    self.total_amount    = subtotal - discount_amount.to_f + tax_amount.to_f
  end

  private

  def generate_quote_number
    return if quote_number.present?
    self.quote_number = "Q-#{Time.current.strftime("%Y%m")}-#{SecureRandom.hex(4).upcase}"
  end
end
