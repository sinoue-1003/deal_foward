class Deal < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :company, optional: true
  belongs_to :owner,   class_name: "User", optional: true

  has_many :deal_contacts,        dependent: :destroy
  has_many :contacts, through: :deal_contacts
  has_many :deal_products,        dependent: :destroy
  has_many :products, through: :deal_products
  has_many :playbooks,            dependent: :destroy
  has_many :communications,       dependent: :destroy
  has_many :agent_reports,        dependent: :destroy
  has_many :agent_runs,           dependent: :destroy
  has_many :tasks,                dependent: :destroy
  has_many :meetings,             dependent: :destroy
  has_many :quotes,               dependent: :destroy
  has_many :contracts,            dependent: :nullify
  has_many :stage_histories,      class_name: "DealStageHistory", dependent: :destroy
  has_many :sequence_enrollments, dependent: :destroy
  has_many :email_messages,       dependent: :destroy
  has_many :sales_events, -> { where(aggregate_type: "Deal") },
           foreign_key: :aggregate_id, primary_key: :id
  has_many :notes, as: :notable,  dependent: :destroy

  STAGES              = %w[prospect qualify demo proposal negotiation closed_won closed_lost].freeze
  SOURCES             = %w[inbound outbound referral partner event web other].freeze
  DEAL_TYPES          = %w[new_business expansion renewal upsell cross_sell].freeze
  FORECAST_CATEGORIES = %w[commit best_case pipeline omitted].freeze

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
  validates :expected_revenue,  numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create  :emit_deal_created
  after_update  :emit_stage_changed,  if: :saved_change_to_stage?
  after_update  :emit_amount_updated, if: :saved_change_to_expected_revenue?
  after_update  :emit_owner_changed,  if: :saved_change_to_owner_id?

  private

  def emit_deal_created
    event = publish_event!("deal.created", payload: {
      title:  title,
      stage:  stage,
      amount: expected_revenue,
      source: source
    })
    # リードモデル（deal_stage_histories）を同期
    stage_histories.create!(
      tenant:          tenant,
      from_stage:      nil,
      to_stage:        stage,
      changed_at:      created_at,
      sales_event_id:  event.id
    )
  end

  def emit_stage_changed
    from, to = saved_change_to_stage
    prev = stage_histories.where(to_stage: from).order(changed_at: :desc).first
    days = prev ? ((Time.current - prev.changed_at) / 86_400).round : nil

    event = publish_event!("deal.stage_changed", payload: {
      from_stage: from,
      to_stage:   to,
      days_in_from_stage: days
    })

    stage_histories.create!(
      tenant:             tenant,
      from_stage:         from,
      to_stage:           to,
      days_in_from_stage: days,
      changed_at:         Time.current,
      sales_event_id:     event.id
    )

    # 受注・失注の専用イベントも発行
    publish_event!("deal.won",  payload: { won_reason: won_reason })  if to == "closed_won"
    publish_event!("deal.lost", payload: { lost_reason: lost_reason }) if to == "closed_lost"
  end

  def emit_amount_updated
    prev, curr = saved_change_to_expected_revenue
    publish_event!("deal.amount_updated", payload: {
      previous_amount: prev,
      new_amount:      curr
    })
  end

  def emit_owner_changed
    prev, curr = saved_change_to_owner_id
    publish_event!("deal.owner_changed", payload: {
      previous_owner_id: prev,
      new_owner_id:      curr
    })
  end
end
