class Contact < ApplicationRecord
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
  has_many :activity_timeline,     dependent: :destroy
  has_many :notes, as: :notable,   dependent: :destroy

  STATUSES           = %w[active inactive unsubscribed bounced].freeze
  PREFERRED_CHANNELS = %w[email phone slack teams line other].freeze
  LANGUAGES          = %w[ja en zh ko fr de es other].freeze

  validates :first_name,        presence: true
  validates :last_name,         presence: true
  validates :status,            inclusion: { in: STATUSES }
  validates :preferred_channel, inclusion: { in: PREFERRED_CHANNELS }, allow_nil: true
  validates :language,          inclusion: { in: LANGUAGES },          allow_nil: true
  validates :lead_score,        numericality: { in: 0..100 },          allow_nil: true

  def full_name
    "#{last_name} #{first_name}".strip
  end
end
