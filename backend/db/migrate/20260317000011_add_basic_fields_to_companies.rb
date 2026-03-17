class AddBasicFieldsToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :description, :text
    add_column :companies, :phone, :string
    add_column :companies, :address, :string
    add_column :companies, :country, :string
    add_column :companies, :employee_count, :integer
    add_column :companies, :annual_revenue, :bigint
    add_column :companies, :capital, :bigint
  end
end
