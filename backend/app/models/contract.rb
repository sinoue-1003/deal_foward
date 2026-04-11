class Contract < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :deal,    optional: true
  belongs_to :company, optional: true
  belongs_to :contact, optional: true
  belongs_to :quote,   optional: true
  belongs_to :owner,   class_name: "User", optional: true

  has_one :customer_health_score, dependent: :destroy

  has_many :sales_events, -> { where(aggregate_type: "Contract") },
           foreign_key: :aggregate_id, primary_key: :id

  STATUSES        = %w[draft active expired terminated renewed].freeze
  CONTRACT_TYPES  = %w[new renewal expansion amendment].freeze
  BILLING_PERIODS = %w[monthly annual one_time multi_year].freeze

  validates :contract_number, presence: true, uniqueness: { scope: :tenant_id }
  validates :status,          inclusion: { in: STATUSES }
  validates :contract_type,   inclusion: { in: CONTRACT_TYPES },  allow_nil: true
  validates :billing_period,  inclusion: { in: BILLING_PERIODS }, allow_nil: true
  validates :value,           numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :generate_contract_number, on: :create
  before_save :compute_recurring_revenue

  scope :active,         -> { where(status: "active") }
  scope :expiring_soon,  -> { active.where(end_date: ..30.days.from_now) }
  scope :up_for_renewal, -> { active.where(renewal_date: ..60.days.from_now) }

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create :emit_contract_created
  after_update :emit_status_event, if: :saved_change_to_status?

  private

  def generate_contract_number
    return if contract_number.present?
    self.contract_number = "C-#{Time.current.strftime("%Y%m")}-#{SecureRandom.hex(4).upcase}"
  end

  def compute_recurring_revenue
    return unless value.present? && billing_period.present?
    case billing_period
    when "monthly"
      self.mrr = value
      self.arr = value * 12
    when "annual"
      self.arr = value
      self.mrr = (value / 12).round(2)
    when "multi_year"
      years = end_date && start_date ? ((end_date - start_date) / 365.0).round(1) : 2
      self.arr = (value / years).round(2)
      self.mrr = (self.arr / 12).round(2)
    end
  end

  def emit_contract_created
    publish_event!("contract.created", payload: {
      deal_id:        deal_id,
      contract_type:  contract_type,
      value:          value,
      arr:            arr,
      currency:       currency,
      billing_period: billing_period
    })
  end

  def emit_status_event
    _prev, curr = saved_change_to_status
    event_type = case curr
                 when "active"     then "contract.activated"
                 when "renewed"    then "contract.renewed"
                 when "terminated" then "contract.terminated"
                 end
    publish_event!(event_type, payload: {
      value: value, arr: arr
    }) if event_type
    publish_event!("contract.signed", payload: {
      signed_by: signed_by, signed_at: signed_at
    }) if curr == "active" && signed_at.present?
  end
end
