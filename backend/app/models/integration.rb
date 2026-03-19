class Integration < ApplicationRecord
  belongs_to :tenant

  TYPES = %w[slack teams zoom google_meet salesforce hubspot gmail].freeze
  validates :integration_type, inclusion: { in: TYPES }, uniqueness: { scope: :tenant_id }
end
