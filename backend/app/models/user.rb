class User < ApplicationRecord
  belongs_to :tenant

  has_secure_password

  ROLES = %w[admin member viewer].freeze

  validates :email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :role, inclusion: { in: ROLES }

  before_validation { self.email = email&.downcase&.strip }

  def admin?
    role == "admin"
  end
end
