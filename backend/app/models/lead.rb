class Lead < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :assigned_to,          class_name: "User",    optional: true
  belongs_to :converted_to_contact, class_name: "Contact", optional: true
  belongs_to :converted_to_deal,    class_name: "Deal",    optional: true

  has_many :sales_events, -> { where(aggregate_type: "Lead") },
           foreign_key: :aggregate_id, primary_key: :id
  has_many :notes, as: :notable, dependent: :destroy

  STATUSES = %w[new working converted disqualified].freeze
  SOURCES  = %w[inbound_form chat referral cold_outreach event partner web other].freeze

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :status,     inclusion: { in: STATUSES }
  validates :source,     inclusion: { in: SOURCES }, allow_nil: true
  validates :score,      numericality: { in: 0..100 }, allow_nil: true

  scope :open,      -> { where(status: %w[new working]) }
  scope :converted, -> { where(status: "converted") }
  scope :hot,       -> { where("score >= 80") }

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create :emit_lead_created
  after_update :emit_field_changes                                    # 全フィールド差分
  after_update :emit_score_updated, if: :saved_change_to_score?
  after_update :emit_assigned,      if: :saved_change_to_assigned_to_id?

  def full_name
    "#{last_name} #{first_name}".strip
  end

  def convert!(contact:, deal: nil)
    update!(
      status:               "converted",
      converted_to_contact: contact,
      converted_to_deal:    deal,
      converted_at:         Time.current
    )
    publish_event!("lead.converted", payload: {
      contact_id: contact.id,
      deal_id:    deal&.id
    })
  end

  def disqualify!(reason:)
    update!(status: "disqualified", disqualified_reason: reason)
    publish_event!("lead.disqualified", payload: { reason: reason })
  end

  private

  def emit_lead_created
    publish_event!("lead.created", payload: {
      source:       source,
      company_name: company_name,
      score:        score
    })
  end

  def emit_score_updated
    prev, curr = saved_change_to_score
    publish_event!("lead.score_updated", payload: {
      previous_score: prev,
      new_score:      curr
    })
  end

  def emit_assigned
    prev, curr = saved_change_to_assigned_to_id
    publish_event!("lead.assigned", payload: {
      previous_assignee_id: prev,
      new_assignee_id:      curr
    })
  end
end
