class Contact < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :company, optional: true
  belongs_to :owner, class_name: "User", optional: true

  has_many :chat_sessions,         dependent: :destroy
  has_many :communications,        dependent: :destroy
  has_many :agent_reports,         dependent: :destroy
  has_many :playbooks,             dependent: :destroy
  has_many :deal_contacts,         dependent: :destroy
  has_many :deals, through: :deal_contacts
  has_many :tasks,                 dependent: :destroy
  has_many :sequence_enrollments,  dependent: :destroy
  has_many :sequences, through: :sequence_enrollments
  has_many :meeting_attendees,     dependent: :destroy
  has_many :meetings, through: :meeting_attendees
  has_many :quotes,                dependent: :nullify
  has_many :contracts,             dependent: :nullify
  has_many :email_messages,        dependent: :destroy
  has_many :notes, as: :notable,   dependent: :destroy

  has_many :sales_events, -> { where(aggregate_type: "Contact") },
           foreign_key: :aggregate_id, primary_key: :id

  STATUSES           = %w[active inactive unsubscribed bounced].freeze
  PREFERRED_CHANNELS = %w[email phone slack teams line other].freeze
  LANGUAGES          = %w[ja en zh ko fr de es other].freeze

  validates :first_name,        presence: true
  validates :last_name,         presence: true
  validates :status,            inclusion: { in: STATUSES }
  validates :preferred_channel, inclusion: { in: PREFERRED_CHANNELS }, allow_nil: true
  validates :language,          inclusion: { in: LANGUAGES },          allow_nil: true
  validates :lead_score,        numericality: { in: 0..100 },          allow_nil: true

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create  :emit_contact_created
  after_update  :emit_status_changed,      if: :saved_change_to_status?
  after_update  :emit_score_updated,       if: :saved_change_to_lead_score?
  after_update  :emit_owner_changed,       if: :saved_change_to_owner_id?
  after_update  :emit_do_not_contact_set,  if: :saved_change_to_do_not_contact?

  def full_name
    "#{last_name} #{first_name}".strip
  end

  private

  def emit_contact_created
    publish_event!("contact.created", payload: {
      company_id: company_id,
      source:     try(:source)
    })
  end

  def emit_status_changed
    prev, curr = saved_change_to_status
    publish_event!("contact.status_changed", payload: {
      previous_status: prev,
      new_status:      curr
    })
  end

  def emit_score_updated
    prev, curr = saved_change_to_lead_score
    publish_event!("contact.score_updated", payload: {
      previous_score: prev,
      new_score:      curr
    })
  end

  def emit_owner_changed
    prev, curr = saved_change_to_owner_id
    publish_event!("contact.owner_changed", payload: {
      previous_owner_id: prev,
      new_owner_id:      curr
    })
  end

  def emit_do_not_contact_set
    _prev, curr = saved_change_to_do_not_contact
    publish_event!("contact.do_not_contact_set", payload: {
      do_not_contact: curr
    }) if curr == true
  end
end
