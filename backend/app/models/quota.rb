class Quota < ApplicationRecord
  belongs_to :tenant
  belongs_to :user
  belongs_to :forecast_period

  QUOTA_TYPES = %w[revenue deal_count activity_count new_logo].freeze

  validates :quota_type,    inclusion: { in: QUOTA_TYPES }
  validates :target_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def attainment_amount(closed_amount)
    return nil unless target_amount&.positive?
    ((closed_amount / target_amount) * 100).round(1)
  end
end
