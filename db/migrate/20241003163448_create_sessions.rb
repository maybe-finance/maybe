class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    remove_column :users, :last_login_at, :datetime
  end
end
