class UserLatestChat < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :current_chat, foreign_key: { to_table: :chats }, null: true, type: :uuid
  end
end
