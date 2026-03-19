class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :companies, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :chat_sessions, dependent: :destroy
  has_many :communications, dependent: :destroy
  has_many :agent_reports, dependent: :destroy
  has_many :playbooks, dependent: :destroy
  has_many :playbook_steps, dependent: :destroy
  has_many :playbook_executions, dependent: :destroy
  has_many :deals, dependent: :destroy
  has_many :deal_contacts, dependent: :destroy
  has_many :integrations, dependent: :destroy
  has_many :agent_runs, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "lowercase letters, numbers, hyphens only" }
  validates :plan, inclusion: { in: %w[starter growth enterprise] }
  validates :status, inclusion: { in: %w[active suspended cancelled] }

  before_validation :generate_slug, on: :create

  # Generate a random agent API key, store its BCrypt digest
  # Returns the plaintext key once — caller must save it
  def regenerate_agent_api_key!
    plaintext = "agt_#{SecureRandom.hex(24)}"
    update!(agent_api_key_digest: BCrypt::Password.create(plaintext))
    plaintext
  end

  # Verify an agent API key against stored digest
  def valid_agent_api_key?(key)
    return false if agent_api_key_digest.blank?
    BCrypt::Password.new(agent_api_key_digest).is_password?(key)
  end

  def active?
    status == "active"
  end

  private

  def generate_slug
    return if slug.present?
    base = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
    candidate = base
    n = 1
    while Tenant.exists?(slug: candidate)
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end
end
