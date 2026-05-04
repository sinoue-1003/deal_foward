class Communication < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true
  belongs_to :contact, optional: true
  belongs_to :deal,    optional: true

  CHANNELS    = %w[slack teams zoom google_meet email salesforce hubspot].freeze
  DIRECTIONS  = %w[inbound outbound].freeze
  SENTIMENTS  = %w[positive neutral negative].freeze

  validates :channel,   inclusion: { in: CHANNELS }
  validates :direction, inclusion: { in: DIRECTIONS }, allow_nil: true
  validates :sentiment, inclusion: { in: SENTIMENTS }, allow_nil: true
  validates :duration_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
