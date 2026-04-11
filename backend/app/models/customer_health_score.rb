class CustomerHealthScore < ApplicationRecord
  belongs_to :tenant
  belongs_to :company
  belongs_to :contract, optional: true

  CHURN_RISKS = %w[low medium high critical].freeze

  validates :overall_score,    numericality: { in: 0..100 }
  validates :usage_score,      numericality: { in: 0..100 }
  validates :support_score,    numericality: { in: 0..100 }
  validates :engagement_score, numericality: { in: 0..100 }
  validates :nps_score,        numericality: { in: -100..100 }, allow_nil: true
  validates :churn_risk,       inclusion: { in: CHURN_RISKS }

  scope :at_risk, -> { where(churn_risk: %w[high critical]) }
  scope :latest,  -> { order(scored_at: :desc) }

  before_save :compute_overall_score

  private

  def compute_overall_score
    scores  = [ usage_score, support_score, engagement_score ].compact
    weights = [ 0.4, 0.3, 0.3 ]
    self.overall_score = scores.zip(weights).sum { |s, w| s * w }.round
    self.churn_risk = case overall_score
                      when 0..25  then "critical"
                      when 26..50 then "high"
                      when 51..70 then "medium"
                      else             "low"
                      end
  end
end
