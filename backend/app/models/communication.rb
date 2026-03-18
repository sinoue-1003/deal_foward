class Communication < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true
  belongs_to :contact, optional: true

  CHANNELS = %w[slack teams zoom google_meet email salesforce hubspot].freeze

  validates :channel, inclusion: { in: CHANNELS }
end
