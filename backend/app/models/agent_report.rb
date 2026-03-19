class AgentReport < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true
  belongs_to :contact, optional: true

  validates :action_taken, presence: true
end
