class ChatMessage < ApplicationRecord
  belongs_to :tenant
  belongs_to :chat_session

  ROLES = %w[user assistant system].freeze

  validates :role,    inclusion: { in: ROLES }
  validates :content, presence: true

  scope :by_role, ->(role) { where(role: role) }
  scope :recent,  -> { order(created_at: :desc) }

  # チャットセッションの全メッセージをAPI形式で返す
  def self.to_api_messages(session_id)
    where(chat_session_id: session_id)
      .order(:created_at)
      .map { |m| { role: m.role, content: m.content } }
  end
end
