class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :name, null: false
      t.string :industry
      t.string :website
      t.string :size
      t.string :crm_id
      t.string :source
      t.timestamps
    end
  end
end
