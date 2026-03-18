class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.references :tenant, null: false, foreign_key: true, type: :uuid
      t.string :email, null: false
      t.string :name
      t.string :role, null: false, default: "member"    # admin, member, viewer
      t.string :password_digest
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :users, [ :tenant_id, :email ], unique: true
    add_index :users, :role
  end
end
