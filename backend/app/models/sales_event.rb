class SalesEvent < ApplicationRecord
  belongs_to :tenant

  # ----------------------------------------------------------------
  # イベント種別定数（セールスフローの全ドメインイベント）
  # ----------------------------------------------------------------
  LEAD_EVENTS = %w[
    lead.created      lead.score_updated   lead.assigned
    lead.converted    lead.disqualified
  ].freeze

  DEAL_EVENTS = %w[
    deal.created       deal.stage_changed   deal.amount_updated
    deal.owner_changed deal.won             deal.lost
  ].freeze

  ENGAGEMENT_EVENTS = %w[
    meeting.scheduled  meeting.completed    meeting.no_show
    email.sent         email.opened         email.replied     email.bounced
    call.made          call.completed       call.no_answer
    chat.started       chat.converted       chat.ended
  ].freeze

  SEQUENCE_EVENTS = %w[
    sequence.enrolled       sequence.step_executed
    sequence.completed      sequence.replied       sequence.opted_out
  ].freeze

  CPQ_EVENTS = %w[
    quote.created   quote.sent    quote.viewed
    quote.accepted  quote.rejected
  ].freeze

  CONTRACT_EVENTS = %w[
    contract.created   contract.signed    contract.activated
    contract.renewed   contract.terminated
  ].freeze

  CS_EVENTS = %w[
    health_score.updated  renewal.flagged  churn.at_risk
  ].freeze

  PLAYBOOK_EVENTS = %w[
    playbook.created  playbook.step_completed  playbook.completed
  ].freeze

  ALL_EVENT_TYPES = (
    LEAD_EVENTS + DEAL_EVENTS + ENGAGEMENT_EVENTS +
    SEQUENCE_EVENTS + CPQ_EVENTS + CONTRACT_EVENTS +
    CS_EVENTS + PLAYBOOK_EVENTS
  ).freeze

  AGGREGATE_TYPES = %w[
    Lead Deal Contact Company Meeting EmailMessage
    Quote Contract Sequence ChatSession Playbook
  ].freeze

  ACTOR_TYPES = %w[user ai_agent system].freeze

  # ----------------------------------------------------------------
  # バリデーション（append-only のため update 系は禁止）
  # ----------------------------------------------------------------
  validates :event_type,      inclusion: { in: ALL_EVENT_TYPES }
  validates :aggregate_type,  inclusion: { in: AGGREGATE_TYPES }
  validates :aggregate_id,    presence: true
  validates :occurred_at,     presence: true

  # ----------------------------------------------------------------
  # スコープ
  # ----------------------------------------------------------------
  scope :for_aggregate,   ->(type, id)  { where(aggregate_type: type, aggregate_id: id).order(:sequence_number) }
  scope :for_deal,        ->(id)        { for_aggregate("Deal", id) }
  scope :for_lead,        ->(id)        { for_aggregate("Lead", id) }
  scope :for_contact,     ->(id)        { for_aggregate("Contact", id) }
  scope :recent,          ->            { order(occurred_at: :desc) }
  scope :of_type,         ->(type)      { where(event_type: type) }
  scope :by_actor,        ->(type, id)  { where("metadata->>'actor_type' = ? AND metadata->>'actor_id' = ?", type, id) }
  scope :since,           ->(time)      { where("occurred_at >= ?", time) }

  # ----------------------------------------------------------------
  # ファクトリ（アプリケーション全体から呼ぶ）
  # ----------------------------------------------------------------
  def self.publish!(
    tenant:,
    event_type:,
    aggregate:,
    payload: {},
    actor_type: "system",
    actor_id: nil,
    occurred_at: Time.current
  )
    # 同一集約の最新 sequence_number を取得して +1
    last_seq = where(
      tenant_id:      tenant.id,
      aggregate_type: aggregate.class.name,
      aggregate_id:   aggregate.id
    ).maximum(:sequence_number) || -1

    create!(
      tenant:         tenant,
      event_type:     event_type,
      aggregate_type: aggregate.class.name,
      aggregate_id:   aggregate.id,
      payload:        payload,
      metadata:       { actor_type: actor_type, actor_id: actor_id },
      sequence_number: last_seq + 1,
      occurred_at:    occurred_at
    )
  end

  # ----------------------------------------------------------------
  # 集約の状態を events から再構築（replay）
  # ----------------------------------------------------------------
  def self.replay(aggregate_type:, aggregate_id:)
    for_aggregate(aggregate_type, aggregate_id).map do |e|
      { event_type: e.event_type, payload: e.payload, occurred_at: e.occurred_at }
    end
  end

  # ----------------------------------------------------------------
  # 更新禁止（append-only 保証）
  # ----------------------------------------------------------------
  before_update { raise ActiveRecord::ReadOnlyRecord, "SalesEvent は append-only です" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "SalesEvent は削除できません" }
end
