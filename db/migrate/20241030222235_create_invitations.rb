class CreateInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :invitations, id: :uuid do |t|
      t.string :email
      t.string :role
      t.string :token
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.references :inviter, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :accepted_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
  end
end
