class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.string :role
      t.string :source_channel
      t.timestamps
    end
  end
end
