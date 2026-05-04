class ForecastPeriod < ApplicationRecord
  belongs_to :tenant

  has_many :forecasts, dependent: :destroy
  has_many :quotas,    dependent: :destroy

  PERIOD_TYPES = %w[monthly quarterly].freeze

  validates :period_type,  inclusion: { in: PERIOD_TYPES }
  validates :fiscal_year,  presence: true
  validates :start_date,   presence: true
  validates :end_date,     presence: true
  validate  :end_after_start

  scope :current, -> { where(is_current: true) }

  def label
    if period_type == "quarterly"
      "FY#{fiscal_year} Q#{fiscal_quarter}"
    else
      "FY#{fiscal_year} M#{fiscal_month}"
    end
  end

  private

  def end_after_start
    return unless start_date && end_date
    errors.add(:end_date, "は start_date より後である必要があります") if end_date <= start_date
  end
end
