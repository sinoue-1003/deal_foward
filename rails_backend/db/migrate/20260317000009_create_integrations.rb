class CreateIntegrations < ActiveRecord::Migration[8.1]
  def change
    create_table :integrations, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :integration_type, null: false
      # types: slack, teams, zoom, google_meet, salesforce, hubspot
      t.string :status, default: "disconnected"  # connected, disconnected, error
      t.jsonb :config, default: {}
      t.datetime :last_synced_at
      t.string :error_message
      t.timestamps
    end
    add_index :integrations, :integration_type, unique: true
  end
end
