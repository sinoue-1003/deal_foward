class Integration < ApplicationRecord
  TYPES = %w[slack teams zoom google_meet salesforce hubspot].freeze
  validates :integration_type, inclusion: { in: TYPES }, uniqueness: true
end
