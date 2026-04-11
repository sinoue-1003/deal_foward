class DealStageHistory < ApplicationRecord
  belongs_to :tenant
  belongs_to :deal
  belongs_to :changed_by, class_name: "User", optional: true

  validates :to_stage, presence: true

  default_scope { order(changed_at: :asc) }

  # ステージごとの平均滞留日数を返す（テナント全体）
  def self.avg_days_by_stage(tenant_id)
    where(tenant_id: tenant_id)
      .where.not(from_stage: nil, days_in_from_stage: nil)
      .group(:from_stage)
      .average(:days_in_from_stage)
  end
end
