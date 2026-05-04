class DealProduct < ApplicationRecord
  belongs_to :tenant
  belongs_to :deal
  belongs_to :product

  validates :name,       presence: true
  validates :quantity,   numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :calculate_total

  private

  def calculate_total
    return unless unit_price
    self.total_price = unit_price * quantity
  end
end
