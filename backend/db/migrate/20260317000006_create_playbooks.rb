class CreatePlaybooks < ActiveRecord::Migration[8.1]
  def change
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
  end
end
