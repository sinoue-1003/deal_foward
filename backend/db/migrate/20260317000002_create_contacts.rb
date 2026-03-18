class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :position
      t.string :department
      t.string :phone
      t.string :mobile
      t.string :crm_id
      t.text :description
      t.timestamps
    end
  end
end
