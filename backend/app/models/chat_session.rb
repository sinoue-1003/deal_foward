class ChatSession < ApplicationRecord
  include Eventable

  belongs_to :tenant
  belongs_to :company,     optional: true
  belongs_to :contact,     optional: true
  belongs_to :assigned_to, class_name: "User", optional: true

  # メッセージは chat_messages テーブルで管理（正規化済み）
  has_many :messages, class_name: "ChatMessage", dependent: :destroy

  has_many :sales_events, -> { where(aggregate_type: "ChatSession") },
           foreign_key: :aggregate_id, primary_key: :id

  STATUSES = %w[active ended converted].freeze
  SOURCES  = %w[organic paid social referral direct email other].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }, allow_nil: true
  validates :intent_score, numericality: { in: 0..100 }, allow_nil: true

  # ── イベント発行 ─────────────────────────────────────────────────
  after_create :emit_chat_started
  after_update :emit_status_event, if: :saved_change_to_status?

  def intent_level
    case intent_score
    when 80..100 then "hot"
    when 60..79  then "warm"
    when 40..59  then "cool"
    else              "cold"
    end
  end

  private

  def emit_chat_started
    publish_event!("chat.started", payload: {
      source: source,
      intent_score: intent_score
    })
  end

  def emit_status_event
    _prev, curr = saved_change_to_status
    event_type = case curr
                 when "converted" then "chat.converted"
                 when "ended"     then "chat.ended"
                 end
    publish_event!(event_type, payload: {
      contact_id:  contact_id,
      intent_score: intent_score
    }) if event_type
  end
end
