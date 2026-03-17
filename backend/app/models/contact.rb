class Contact < ApplicationRecord
  belongs_to :company, optional: true
  has_many :chat_sessions
  has_many :communications
  has_many :agent_reports
  has_many :playbooks
  has_many :deal_contacts, dependent: :destroy
  has_many :deals, through: :deal_contacts

  validates :name, presence: true
end
