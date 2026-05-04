class User < ApplicationRecord
  belongs_to :tenant

  has_secure_password

  has_many :owned_companies,   class_name: "Company",   foreign_key: :owner_id, dependent: :nullify
  has_many :owned_contacts,    class_name: "Contact",   foreign_key: :owner_id, dependent: :nullify
  has_many :owned_deals,       class_name: "Deal",      foreign_key: :owner_id, dependent: :nullify
  has_many :owned_territories, class_name: "Territory", foreign_key: :owner_id, dependent: :nullify
  has_many :assigned_chat_sessions, class_name: "ChatSession", foreign_key: :assigned_to_id, dependent: :nullify
  has_many :quotas,             dependent: :destroy
  has_many :forecasts,          dependent: :destroy
  has_many :deal_stage_changes, class_name: "DealStageHistory", foreign_key: :changed_by_id, dependent: :nullify

  ROLES = %w[admin member viewer].freeze

  validates :email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :role, inclusion: { in: ROLES }

  before_validation { self.email = email&.downcase&.strip }

  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end
end
