class AddFamilyIdToChats < ActiveRecord::Migration[7.2]
  def change
    add_reference :chats, :family, null: false, foreign_key: true, type: :uuid
  end
end
