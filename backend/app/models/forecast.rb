class Forecast < ApplicationRecord
  belongs_to :tenant
  belongs_to :forecast_period
  belongs_to :user
  belongs_to :submitted_for, class_name: "User", optional: true

  validates :commit_amount,    numericality: { greater_than_or_equal_to: 0 }
  validates :best_case_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :pipeline_amount,  numericality: { greater_than_or_equal_to: 0 }
  validates :closed_amount,    numericality: { greater_than_or_equal_to: 0 }

  # 達成率（対クォータ）
  def attainment_pct(quota)
    return nil unless quota&.target_amount&.positive?
    ((closed_amount / quota.target_amount) * 100).round(1)
  end
end
