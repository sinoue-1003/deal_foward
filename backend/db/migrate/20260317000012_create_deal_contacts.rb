class CreateDealContacts < ActiveRecord::Migration[8.1]
  def change
    # Remove single contact_id from deals
    remove_reference :deals, :contact, type: :uuid, foreign_key: true

    # Create join table for deals <-> contacts (many-to-many)
    create_table :deal_contacts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :deal, type: :uuid, null: false, foreign_key: true
      t.references :contact, type: :uuid, null: false, foreign_key: true
      t.string :role  # 役割: decision_maker, influencer, user, champion など
      t.timestamps
    end

    add_index :deal_contacts, [:deal_id, :contact_id], unique: true
  end
end
