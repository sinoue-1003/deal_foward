class CreatePlaybookSteps < ActiveRecord::Migration[8.1]
  def change
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
  end
end
