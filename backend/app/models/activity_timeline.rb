class ActivityTimeline < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true
  belongs_to :contact, optional: true
  belongs_to :deal,    optional: true

  ACTIVITY_TYPES = %w[
    email_sent          email_received      call_made
    meeting_held        meeting_scheduled   deal_stage_changed
    deal_created        deal_won            deal_lost
    note_added          task_completed      task_created
    sequence_enrolled   playbook_executed   playbook_step_completed
    lead_created        lead_converted      contact_created
    quote_sent          quote_accepted      contract_signed
    chat_converted      agent_report_filed
  ].freeze

  ACTOR_TYPES = %w[user ai_agent system].freeze

  validates :activity_type, inclusion: { in: ACTIVITY_TYPES }
  validates :actor_type,    inclusion: { in: ACTOR_TYPES }
  validates :occurred_at,   presence: true

  scope :for_deal,    ->(deal_id)    { where(deal_id: deal_id).order(occurred_at: :desc) }
  scope :for_contact, ->(contact_id) { where(contact_id: contact_id).order(occurred_at: :desc) }
  scope :for_company, ->(company_id) { where(company_id: company_id).order(occurred_at: :desc) }
  scope :recent,      -> { order(occurred_at: :desc) }

  # 他モデルのコールバックから呼び出すファクトリメソッド
  def self.log(tenant:, type:, actor_type: "system", actor_id: nil,
               company: nil, contact: nil, deal: nil,
               title: nil, description: nil, metadata: {})
    create!(
      tenant:        tenant,
      activity_type: type,
      actor_type:    actor_type,
      actor_id:      actor_id,
      company:       company,
      contact:       contact,
      deal:          deal,
      title:         title,
      description:   description,
      metadata:      metadata,
      occurred_at:   Time.current
    )
  end
end
