class Company < ApplicationRecord
  has_many :contacts
  has_many :chat_sessions
  has_many :communications
  has_many :agent_reports
  has_many :playbooks
  has_many :deals

  validates :name, presence: true
end
