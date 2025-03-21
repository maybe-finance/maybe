class CreateAiChats < ActiveRecord::Migration[7.2]
  def change
    create_table :chats, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.string :instructions
      t.string :error
      t.timestamps
    end

    create_table :messages, id: :uuid do |t|
      t.references :chat, null: false, foreign_key: true, type: :uuid
      t.string :provider_id
      t.string :ai_model
      t.string :role, null: false
      t.string :kind, null: false, default: "text"
      t.string :status, null: false, default: "complete"
      t.text :content

      t.timestamps
    end

    create_table :tool_calls, id: :uuid do |t|
      t.references :message, null: false, foreign_key: true, type: :uuid
      t.string :provider_id, null: false
      t.string :provider_fn_call_id, null: false
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
