class CreatePlaybookExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :playbook_executions, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :playbook, type: :uuid, foreign_key: true
      t.integer :step_index, null: false
      t.string :status  # pending, in_progress, completed, failed, skipped
      t.text :result
      t.string :executed_by  # ai_agent or human username
      t.datetime :executed_at
      t.timestamps
    end
  end
end
