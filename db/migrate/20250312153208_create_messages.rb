class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages, id: :uuid do |t|
      t.timestamps

      t.references :chat, null: false, foreign_key: true, type: :uuid
      t.string :role, null: false
      t.text :content, null: false
      t.boolean :debug_mode, default: false, null: false
    end
  end
end
