class Product < ApplicationRecord
  belongs_to :tenant

  has_many :quote_line_items, dependent: :nullify

  PRODUCT_TYPES   = %w[one_time recurring usage_based].freeze
  BILLING_PERIODS = %w[monthly annual one_time multi_year].freeze

  validates :name,           presence: true
  validates :product_type,   inclusion: { in: PRODUCT_TYPES }
  validates :billing_period, inclusion: { in: BILLING_PERIODS }, allow_nil: true
  validates :default_price,  numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(is_active: true) }

  # 月次換算価格
  def monthly_price
    return nil if default_price.nil?
    case billing_period
    when "monthly"    then default_price
    when "annual"     then (default_price / 12).round(2)
    when "multi_year" then (default_price / 24).round(2)
    else default_price
    end
  end

  # 年間換算価格（ARR）
  def annual_price
    return nil if default_price.nil?
    case billing_period
    when "monthly"    then (default_price * 12).round(2)
    when "annual"     then default_price
    when "multi_year" then (default_price / 2).round(2)
    else nil
    end
  end
end
