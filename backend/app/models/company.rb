class Company < ApplicationRecord
  belongs_to :tenant

  has_many :contacts
  has_many :chat_sessions
  has_many :communications
  has_many :agent_reports
  has_many :playbooks
  has_many :deals

  validates :name, presence: true
  validates :employee_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :annual_revenue, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :capital, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
