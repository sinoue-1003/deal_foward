class Quote < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :deal,        optional: true
  belongs_to :contact,     optional: true
  belongs_to :created_by,  class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true

  has_many :line_items, class_name: "QuoteLineItem", dependent: :destroy
  has_many :products, through: :line_items
  has_one  :contract, dependent: :nullify

  has_many :sales_events, -> { where(aggregate_type: "Quote") },
           foreign_key: :aggregate_id, primary_key: :id

  STATUSES = %w[draft sent viewed accepted rejected expired].freeze

  validates :quote_number, presence: true, uniqueness: { scope: :tenant_id }
  validates :status,       inclusion: { in: STATUSES }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :generate_quote_number, on: :create
  before_save :recalculate_totals

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create :emit_quote_created
  after_update :emit_field_changes                                    # 全フィールド差分
  after_update :emit_status_event, if: :saved_change_to_status?

  scope :active, -> { where(status: %w[draft sent viewed]) }

  private

  def recalculate_totals
    self.subtotal     = line_items.sum(&:total_price) || 0
    self.total_amount = subtotal - discount_amount.to_f + tax_amount.to_f
  end

  def generate_quote_number
    return if quote_number.present?
    self.quote_number = "Q-#{Time.current.strftime("%Y%m")}-#{SecureRandom.hex(4).upcase}"
  end

  def emit_quote_created
    publish_event!("quote.created", payload: {
      deal_id:      deal_id,
      total_amount: total_amount,
      currency:     currency
    })
  end

  def emit_status_event
    _prev, curr = saved_change_to_status
    event_type = case curr
                 when "sent"     then "quote.sent"
                 when "viewed"   then "quote.viewed"
                 when "accepted" then "quote.accepted"
                 when "rejected" then "quote.rejected"
                 when "expired"  then nil
                 end
    publish_event!(event_type, payload: {
      deal_id:      deal_id,
      total_amount: total_amount
    }) if event_type
  end
end
