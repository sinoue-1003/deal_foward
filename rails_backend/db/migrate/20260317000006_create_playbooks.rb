class CreatePlaybooks < ActiveRecord::Migration[8.1]
  def change
    create_table :playbooks, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.references :contact, type: :uuid, foreign_key: true
      t.string :title, null: false
      t.string :status, default: "active"  # active, paused, completed
      t.jsonb :steps, default: []
      # steps format: [{step, action_type, channel, target, template, due_in_hours, status, result, completed_at}]
      t.integer :current_step, default: 0
      t.string :created_by, default: "ai_agent"
      t.text :objective        # What this playbook is trying to achieve
      t.text :situation_summary # Current situation summary (shared AI+human context)
      t.timestamps
    end
    add_index :playbooks, :status
  end
end
