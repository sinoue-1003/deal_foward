class MeetingInsight < ApplicationRecord
  belongs_to :tenant
  belongs_to :meeting

  validates :sentiment_score,  numericality: { in: -100..100 }, allow_nil: true
  validates :engagement_score, numericality: { in: 0..100 },    allow_nil: true
  validates :talk_ratio_rep,   numericality: { in: 0..100 },    allow_nil: true

  def analyzed?
    analyzed_at.present?
  end

  def risk_level
    flags = risk_flags.to_a
    return "none"   if flags.empty?
    return "high"   if flags.count >= 3
    return "medium" if flags.count >= 1
    "low"
  end
end
