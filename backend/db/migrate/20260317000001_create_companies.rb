class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :name, null: false
      t.string :industry
      t.string :website
      t.string :crm_id
      t.text :description
      t.string :phone
      t.string :address
      t.string :country
      t.integer :employee_count
      t.bigint :annual_revenue
      t.bigint :capital
      t.timestamps
    end
  end
end
