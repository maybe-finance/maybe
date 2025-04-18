class CreateAiChats < ActiveRecord::Migration[7.2]
  def change
    create_table :chats, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.string :instructions
      t.jsonb :error
      t.string :latest_assistant_response_id
      t.timestamps
    end

    create_table :messages, id: :uuid do |t|
      t.references :chat, null: false, foreign_key: true, type: :uuid
      t.string :type, null: false
      t.string :status, null: false, default: "complete"
      t.text :content
      t.string :ai_model
      t.timestamps

      # Developer message fields
      t.boolean :debug, default: false

      # Assistant message fields
      t.string :provider_id
      t.boolean :reasoning, default: false
    end

    create_table :tool_calls, id: :uuid do |t|
      t.references :message, null: false, foreign_key: true, type: :uuid
      t.string :provider_id, null: false
      t.string :provider_call_id
      t.string :type, null: false

      # Function specific fields
      t.string :function_name
      t.jsonb :function_arguments
      t.jsonb :function_result

      t.timestamps
    end

    add_reference :users, :last_viewed_chat, foreign_key: { to_table: :chats }, null: true, type: :uuid
    add_column :users, :show_ai_sidebar, :boolean, default: true
    add_column :users, :ai_enabled, :boolean, default: false, null: false
  end
end
