class Deal < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true
  belongs_to :owner, class_name: "User", optional: true

  has_many :deal_contacts,       dependent: :destroy
  has_many :contacts, through: :deal_contacts
  has_many :playbooks,           dependent: :destroy
  has_many :communications,      dependent: :destroy
  has_many :agent_reports,       dependent: :destroy
  has_many :agent_runs,          dependent: :destroy
  has_many :tasks,               dependent: :destroy
  has_many :meetings,            dependent: :destroy
  has_many :quotes,              dependent: :destroy
  has_many :contracts,           dependent: :nullify
  has_many :stage_histories,     class_name: "DealStageHistory", dependent: :destroy
  has_many :sequence_enrollments, dependent: :destroy
  has_many :email_messages,      dependent: :destroy
  has_many :activity_timeline,   dependent: :destroy
  has_many :notes, as: :notable, dependent: :destroy

  STAGES              = %w[prospect qualify demo proposal negotiation closed_won closed_lost].freeze
  SOURCES             = %w[inbound outbound referral partner event web other].freeze
  DEAL_TYPES          = %w[new_business expansion renewal upsell cross_sell].freeze
  FORECAST_CATEGORIES = %w[commit best_case pipeline omitted].freeze
  LOST_REASONS        = %w[price competitor timing no_budget no_decision other].freeze

  enum :lost_reason, {
    price:       "price",
    competitor:  "competitor",
    timing:      "timing",
    no_budget:   "no_budget",
    no_decision: "no_decision",
    other:       "other"
  }

  validates :title,             presence: true
  validates :stage,             inclusion: { in: STAGES }
  validates :deal_type,         inclusion: { in: DEAL_TYPES },          allow_nil: true
  validates :source,            inclusion: { in: SOURCES },             allow_nil: true
  validates :forecast_category, inclusion: { in: FORECAST_CATEGORIES }, allow_nil: true
  validates :probability,       numericality: { in: 0..100 },           allow_nil: true
  validates :budget,            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :amount,            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  after_update :record_stage_history, if: :saved_change_to_stage?

  private

  def record_stage_history
    from, to = saved_change_to_stage
    stage_histories.create!(
      tenant:     tenant,
      from_stage: from,
      to_stage:   to,
      changed_at: Time.current
    )
  end
end
