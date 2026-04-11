module Eventable
  extend ActiveSupport::Concern

  # ----------------------------------------------------------------
  # フィールド差分追跡から除外するシステムカラム
  # ----------------------------------------------------------------
  DIFF_IGNORED_FIELDS = %w[
    updated_at created_at tenant_id
  ].freeze

  # ----------------------------------------------------------------
  # インクルード先のモデルで使えるクラスメソッド
  # ----------------------------------------------------------------
  included do
    # actor を Current オブジェクトから取得できるようにする
    # Current.user が設定されていれば user として記録
    # なければ system として記録
  end

  # ----------------------------------------------------------------
  # イベント発行ヘルパー
  # ----------------------------------------------------------------
  def publish_event!(event_type, payload: {}, actor_type: nil, actor_id: nil)
    actor_type ||= resolve_actor_type
    actor_id   ||= resolve_actor_id

    SalesEvent.publish!(
      tenant:      tenant,
      event_type:  event_type,
      aggregate:   self,
      payload:     payload,
      actor_type:  actor_type,
      actor_id:    actor_id
    )
  end

  # ----------------------------------------------------------------
  # 汎用フィールド差分イベント発行
  #   after_update :emit_field_changes を各モデルに書くだけで
  #   変更されたカラムの前後値が "<aggregate>.updated" に記録される
  #
  #   payload 例:
  #   {
  #     "changes": {
  #       "phone":          [nil, "03-1234-5678"],
  #       "employee_count": [50, 120],
  #       "account_type":   ["prospect", "customer"]
  #     }
  #   }
  # ----------------------------------------------------------------
  def emit_field_changes
    diff = saved_changes.except(*DIFF_IGNORED_FIELDS)
    return if diff.empty?

    aggregate_name = self.class.name.underscore  # "company" / "deal" など
    publish_event!("#{aggregate_name}.updated", payload: { changes: diff })
  end

  # ----------------------------------------------------------------
  # このエンティティに関連する全イベントを時系列で返す
  # ----------------------------------------------------------------
  def event_history
    SalesEvent.for_aggregate(self.class.name, id)
  end

  # ----------------------------------------------------------------
  # 最後のイベントを返す
  # ----------------------------------------------------------------
  def last_event
    event_history.last
  end

  private

  def resolve_actor_type
    return "user"     if Current.user.present?
    return "ai_agent" if Current.agent.present?
    "system"
  end

  def resolve_actor_id
    Current.user&.id || Current.agent&.id
  end
end
