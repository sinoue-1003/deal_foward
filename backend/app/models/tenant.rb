class Tenant < ApplicationRecord
  # ── 既存テーブル ──────────────────────────────────────────────────
  has_many :users,                dependent: :destroy
  has_many :companies,            dependent: :destroy
  has_many :contacts,             dependent: :destroy
  has_many :chat_sessions,        dependent: :destroy
  has_many :chat_messages,        dependent: :destroy
  has_many :communications,       dependent: :destroy
  has_many :agent_reports,        dependent: :destroy
  has_many :agent_runs,           dependent: :destroy
  has_many :playbooks,            dependent: :destroy
  has_many :playbook_steps,       dependent: :destroy
  has_many :playbook_executions,  dependent: :destroy
  has_many :deals,                dependent: :destroy
  has_many :deal_contacts,        dependent: :destroy
  has_many :integrations,         dependent: :destroy
  has_many :tasks,                dependent: :destroy

  # ── 新規テーブル ──────────────────────────────────────────────────
  has_many :leads,                  dependent: :destroy
  has_many :products,               dependent: :destroy
  has_many :quotes,                 dependent: :destroy
  has_many :quote_line_items,       dependent: :destroy
  has_many :contracts,              dependent: :destroy
  has_many :sequences,              dependent: :destroy
  has_many :sequence_steps,         dependent: :destroy
  has_many :sequence_enrollments,   dependent: :destroy
  has_many :meetings,               dependent: :destroy
  has_many :meeting_attendees,      dependent: :destroy
  has_many :meeting_insights,       dependent: :destroy
  has_many :deal_stage_histories,   dependent: :destroy
  has_many :forecast_periods,       dependent: :destroy
  has_many :forecasts,              dependent: :destroy
  has_many :territories,            dependent: :destroy
  has_many :territory_assignments,  dependent: :destroy
  has_many :quotas,                 dependent: :destroy
  has_many :notes,                  dependent: :destroy
  has_many :sales_events,           dependent: :destroy
  has_many :email_messages,         dependent: :destroy
  has_many :customer_health_scores, dependent: :destroy
  has_many :audit_logs,             dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "lowercase letters, numbers, hyphens only" }
  validates :plan,   inclusion: { in: %w[starter growth enterprise] }
  validates :status, inclusion: { in: %w[active suspended cancelled] }

  before_validation :generate_slug, on: :create

  def regenerate_agent_api_key!
    plaintext = "agt_#{SecureRandom.hex(24)}"
    update!(agent_api_key_digest: BCrypt::Password.create(plaintext))
    plaintext
  end

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
