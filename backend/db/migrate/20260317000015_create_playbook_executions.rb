class CreatePlaybookExecutions < ActiveRecord::Migration[8.1]
  def change
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
