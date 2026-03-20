class CreateInitialSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :companies, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :name, null: false
      t.string :industry
      t.string :website
      t.string :crm_id
      t.text :description
      t.string :phone
      t.string :address
      t.string :country
      t.integer :employee_count
      t.bigint :annual_revenue
      t.bigint :capital
      t.timestamps
    end

    create_table :contacts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :position
      t.string :department
      t.string :phone
      t.string :mobile
      t.string :crm_id
      t.text :description
      t.timestamps
    end

    create_table :chat_sessions, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :contact, type: :uuid, foreign_key: true
      t.references :company, type: :uuid, foreign_key: true
      t.jsonb :messages, default: []
      t.integer :intent_score, default: 0
      t.string :status, default: "active"
      t.datetime :ended_at
      t.timestamps
    end

    # external_id を最初から含める (旧: add_external_id_to_communications)
    create_table :communications, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.references :contact, type: :uuid, foreign_key: true
      t.string :channel, null: false  # slack, teams, zoom, google_meet, email
      t.string :external_id
      t.text :content
      t.text :summary
      t.string :sentiment
      t.jsonb :keywords, default: []
      t.jsonb :action_items, default: []
      t.datetime :recorded_at
      t.datetime :analyzed_at
      t.timestamps
    end
    add_index :communications, :channel
    add_index :communications, :external_id, unique: true

    create_table :agent_reports, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.references :contact, type: :uuid, foreign_key: true
      t.string :action_taken
      t.jsonb :insights, default: {}
      t.jsonb :next_recommended_actions, default: []
      t.string :status, default: "pending"  # pending, in_progress, completed
      t.timestamps
    end

    create_table :playbooks, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.references :contact, type: :uuid, foreign_key: true
      t.string :title, null: false
      t.string :status, default: "active"  # active, paused, completed
      t.string :created_by, default: "ai_agent"
      t.text :objective
      t.text :situation_summary
      t.timestamps
    end
    add_index :playbooks, :status

    # contact_id は deal_contacts テーブルで管理 (多対多)
    # lost_reason を最初から含める (旧: add_lost_reason_to_deals)
    create_table :deals, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.string :title, null: false
      t.string :stage, default: "prospect"
      # stages: prospect, qualify, demo, proposal, negotiation, closed_won, closed_lost
      t.decimal :amount, precision: 15, scale: 2
      t.integer :probability, default: 0
      t.string :owner
      t.date :close_date
      t.text :notes
      t.string :lost_reason  # price, competitor, timing, no_budget, no_decision, other
      t.timestamps
    end
    add_index :deals, :stage

    create_table :integrations, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :integration_type, null: false
      # types: slack, teams, zoom, google_meet, salesforce, hubspot
      t.string :status, default: "disconnected"  # connected, disconnected, error
      t.jsonb :config, default: {}
      t.datetime :last_synced_at
      t.string :error_message
      t.timestamps
    end

    create_table :agent_runs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :company,  type: :uuid, foreign_key: true, null: true
      t.references :playbook, type: :uuid, foreign_key: true, null: true
      t.string  :status,           null: false, default: "analyzing"
      t.jsonb   :messages,         null: false, default: []
      t.jsonb   :tool_calls,       null: false, default: []
      t.jsonb   :pending_approval, null: true
      t.string  :trigger,          null: false, default: "manual"
      t.text    :error_message
      t.timestamps
    end
    add_index :agent_runs, :status
    add_index :agent_runs, [ :company_id, :status ]

    # deals <-> contacts の多対多 (旧: create_deal_contacts)
    create_table :deal_contacts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :deal,    type: :uuid, null: false, foreign_key: true
      t.references :contact, type: :uuid, null: false, foreign_key: true
      t.string :role  # decision_maker, influencer, user, champion など
      t.timestamps
    end
    add_index :deal_contacts, [ :deal_id, :contact_id ], unique: true

    create_table :playbook_steps, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :playbook, type: :uuid, foreign_key: true, null: false
      t.integer :step_index, null: false
      t.string :action_type, null: false
      t.string :executor_type, null: false  # ai / human / customer
      t.string :channel
      t.string :target
      t.text :template
      t.integer :due_in_hours
      t.string :status, default: "pending"  # pending, in_progress, completed, failed, skipped
      t.string :executed_by
      t.datetime :completed_at
      t.timestamps
    end
    add_index :playbook_steps, [ :playbook_id, :step_index ], unique: true
    add_index :playbook_steps, :status

    create_table :playbook_executions, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :playbook,      type: :uuid, foreign_key: true, null: false
      t.references :playbook_step, type: :uuid, foreign_key: true, null: false
      t.string :status   # completed, failed, skipped
      t.text :action_content  # 実際に実行した内容
      t.text :result          # 実行結果・アウトカム
      t.string :executed_by   # ai_agent or human username
      t.datetime :executed_at
      t.timestamps
    end
  end
end
