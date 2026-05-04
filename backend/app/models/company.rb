class Company < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :parent_company, class_name: "Company", optional: true
  belongs_to :owner,          class_name: "User",    optional: true

  has_many :subsidiary_companies, class_name: "Company", foreign_key: :parent_company_id, dependent: :nullify
  has_many :contacts,              dependent: :destroy
  has_many :deals,                 dependent: :destroy
  has_many :communications,        dependent: :destroy
  has_many :chat_sessions,         dependent: :destroy
  has_many :agent_reports,         dependent: :destroy
  has_many :playbooks,             dependent: :destroy
  has_many :tasks,                 dependent: :destroy
  has_many :meetings,              dependent: :destroy
  has_many :contracts,             dependent: :destroy
  has_many :territory_assignments, dependent: :destroy
  has_many :territories, through: :territory_assignments
  has_many :customer_health_scores, dependent: :destroy
  has_many :email_messages,         dependent: :destroy
  has_many :notes, as: :notable,    dependent: :destroy

  has_many :sales_events, -> { where(aggregate_type: "Company") },
           foreign_key: :aggregate_id, primary_key: :id

  ACCOUNT_TYPES  = %w[prospect customer at_risk churned partner].freeze
  LISTED_MARKETS = %w[TSE_Prime TSE_Standard TSE_Growth NYSE NASDAQ Other 未上場].freeze

  validates :name,          presence: true
  validates :account_type,  inclusion: { in: ACCOUNT_TYPES }
  validates :fiscal_month,  numericality: { only_integer: true, in: 1..12 },          allow_nil: true
  validates :founding_year, numericality: { only_integer: true, greater_than: 1800 }, allow_nil: true
  validates :employee_count, numericality: { only_integer: true, greater_than: 0 },   allow_nil: true
  validates :annual_revenue, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :capital,        numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create  :emit_company_created
  after_update  :emit_field_changes                                        # 全フィールド差分
  after_update  :emit_account_type_changed, if: :saved_change_to_account_type?
  after_update  :emit_owner_changed,        if: :saved_change_to_owner_id?

  private

  def emit_company_created
    publish_event!("company.created", payload: {
      name:         name,
      account_type: account_type,
      industry:     try(:industry)
    })
  end

  def emit_account_type_changed
    prev, curr = saved_change_to_account_type
    publish_event!("company.account_type_changed", payload: {
      previous_type: prev,
      new_type:      curr
    })
  end

  def emit_owner_changed
    prev, curr = saved_change_to_owner_id
    publish_event!("company.owner_changed", payload: {
      previous_owner_id: prev,
      new_owner_id:      curr
    })
  end
end
