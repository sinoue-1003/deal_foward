class CreateAgentRuns < ActiveRecord::Migration[8.1]
  def change
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
    add_index :agent_runs, [:company_id, :status]
  end
end
