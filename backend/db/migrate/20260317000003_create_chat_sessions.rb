class CreateChatSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_sessions, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :contact, type: :uuid, foreign_key: true
      t.references :company, type: :uuid, foreign_key: true
      t.jsonb :messages, default: []
      t.integer :intent_score, default: 0
      t.string :status, default: "active"
      t.datetime :ended_at
      t.timestamps
    end
  end
end
