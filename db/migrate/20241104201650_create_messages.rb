class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages, id: :uuid do |t|
      t.references :chat, null: false, foreign_key: true, type: :uuid
      t.references :user, foreign_key: true, type: :uuid, null: true
      t.text :content
      t.text :log
      t.string :role
      t.string :status, default: "pending"
      t.timestamps
    end
  end
end
