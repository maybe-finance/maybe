class CreateChats < ActiveRecord::Migration[7.2]
  def change
    create_table :chats, id: :uuid do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
