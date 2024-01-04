class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations, id: :uuid do |t|
      t.string :title
      t.text :summary
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :status
      t.string :role
      t.string :kind
      t.string :subkind

      t.timestamps
    end
  end
end
