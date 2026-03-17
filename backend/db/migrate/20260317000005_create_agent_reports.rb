class CreateAgentReports < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_reports, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.references :contact, type: :uuid, foreign_key: true
      t.string :action_taken
      t.jsonb :insights, default: {}
      t.jsonb :next_recommended_actions, default: []
      t.string :status, default: "pending"  # pending, in_progress, completed
      t.timestamps
    end
  end
end
