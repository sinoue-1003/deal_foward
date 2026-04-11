class QuoteLineItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :quote
  belongs_to :product, optional: true

  validates :name,        presence: true
  validates :quantity,    numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price,  numericality: { greater_than_or_equal_to: 0 }
  validates :discount_pct, numericality: { in: 0..100 }, allow_nil: true

  before_save :calculate_total

  default_scope { order(:sort_order) }

  private

  def calculate_total
    discount = (unit_price * quantity) * (discount_pct.to_f / 100)
    self.total_price = (unit_price * quantity) - discount
  end
end
