class Company < ApplicationRecord
  belongs_to :tenant

  has_many :contacts
  has_many :chat_sessions
  has_many :communications
  has_many :agent_reports
  has_many :playbooks
  has_many :deals
  has_many :tasks

  LISTED_MARKETS = %w[TSE_Prime TSE_Standard TSE_Growth NYSE NASDAQ Other 未上場].freeze

  validates :name,           presence: true
  validates :fiscal_month,   numericality: { only_integer: true, in: 1..12 },             allow_nil: true
  validates :founding_year,  numericality: { only_integer: true, greater_than: 1800 },    allow_nil: true
  validates :employee_count, numericality: { only_integer: true, greater_than: 0 },       allow_nil: true
  validates :annual_revenue, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :capital,        numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
