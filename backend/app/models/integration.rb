class Integration < ApplicationRecord
  TYPES = %w[slack teams zoom google_meet salesforce hubspot gmail].freeze
  validates :integration_type, inclusion: { in: TYPES }, uniqueness: true
end
