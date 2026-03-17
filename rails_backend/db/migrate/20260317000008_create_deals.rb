class CreateDeals < ActiveRecord::Migration[8.1]
  def change
    create_table :deals, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.references :contact, type: :uuid, foreign_key: true
      t.string :title, null: false
      t.string :stage, default: "prospect"
      # stages: prospect, qualify, demo, proposal, negotiation, closed_won, closed_lost
      t.decimal :amount, precision: 15, scale: 2
      t.integer :probability, default: 0
      t.string :owner
      t.date :close_date
      t.text :notes
      t.timestamps
    end
    add_index :deals, :stage
  end
end
