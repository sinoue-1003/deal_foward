module Eventable
  extend ActiveSupport::Concern

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
