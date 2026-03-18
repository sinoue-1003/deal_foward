class AddExternalIdToCommunications < ActiveRecord::Migration[8.1]
  def change
    add_column :communications, :external_id, :string
    add_index  :communications, :external_id, unique: true
  end
end
