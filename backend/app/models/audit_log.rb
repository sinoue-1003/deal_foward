class AuditLog < ApplicationRecord
  belongs_to :tenant
  belongs_to :user, optional: true  # システム操作はuserなし

  ACTIONS        = %w[create update delete view export].freeze
  ENTITY_TYPES   = %w[
    Company Contact Deal Lead Playbook PlaybookStep Communication
    ChatSession Quote Contract Meeting Sequence Product Territory User
  ].freeze

  validates :entity_type, inclusion: { in: ENTITY_TYPES }
  validates :entity_id,   presence: true
  validates :action,      inclusion: { in: ACTIONS }
  validates :occurred_at, presence: true

  scope :recent,          -> { order(occurred_at: :desc) }
  scope :for_entity,      ->(type, id) { where(entity_type: type, entity_id: id) }
  scope :by_user,         ->(user_id)  { where(user_id: user_id) }

  # アプリケーション全体から呼び出すファクトリメソッド
  def self.record(tenant:, action:, entity:, user: nil, changed_fields: {}, request: nil)
    create!(
      tenant:         tenant,
      user:           user,
      entity_type:    entity.class.name,
      entity_id:      entity.id,
      action:         action,
      changed_fields: changed_fields,
      ip_address:     request&.remote_ip,
      user_agent:     request&.user_agent,
      occurred_at:    Time.current
    )
  end
end
