class CreateCommunications < ActiveRecord::Migration[8.1]
  def change
    create_table :communications, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :company, type: :uuid, foreign_key: true
      t.references :contact, type: :uuid, foreign_key: true
      t.string :channel, null: false  # slack, teams, zoom, google_meet, email
      t.text :content
      t.text :summary
      t.string :sentiment
      t.jsonb :keywords, default: []
      t.jsonb :action_items, default: []
      t.datetime :recorded_at
      t.datetime :analyzed_at
      t.timestamps
    end
    add_index :communications, :channel
  end
end
