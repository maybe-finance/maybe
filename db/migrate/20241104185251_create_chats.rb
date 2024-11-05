class CreateChats < ActiveRecord::Migration[7.2]
  def change
    create_table :chats, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :title
      t.text :summary
      t.timestamps
    end
  end
end
