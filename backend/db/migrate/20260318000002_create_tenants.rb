class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :plan, null: false, default: "starter"   # starter, growth, enterprise
      t.string :status, null: false, default: "active"  # active, suspended, cancelled
      t.string :agent_api_key_digest                     # BCrypt digest of agent API key
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :tenants, :slug, unique: true
    add_index :tenants, :status
  end
end
