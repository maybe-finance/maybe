class CreateAiChat < ActiveRecord::Migration[7.2]
  def change
    create_table :chats, id: :uuid do |t|
      t.timestamps
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.string :instructions
    end

    create_table :messages, id: :uuid do |t|
      t.timestamps
      t.references :chat, null: false, foreign_key: true, type: :uuid
      t.text :openai_id
      t.string :role, null: false, default: "user"
      t.string :message_type, null: false, default: "text"
      t.text :content, null: false
    end

    add_reference :users, :last_viewed_chat, foreign_key: { to_table: :chats }, null: true, type: :uuid
    add_column :users, :show_ai_sidebar, :boolean, default: true
    add_column :users, :ai_enabled, :boolean, default: false, null: false
  end
end
