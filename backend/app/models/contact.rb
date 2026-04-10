class Contact < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true

  has_many :chat_sessions
  has_many :communications
  has_many :agent_reports
  has_many :playbooks
  has_many :deal_contacts, dependent: :destroy
  has_many :deals, through: :deal_contacts
  has_many :tasks

  PREFERRED_CHANNELS = %w[email phone slack teams line other].freeze
  LANGUAGES          = %w[ja en zh ko fr de es other].freeze

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :preferred_channel, inclusion: { in: PREFERRED_CHANNELS }, allow_nil: true
  validates :language,          inclusion: { in: LANGUAGES },          allow_nil: true
end
