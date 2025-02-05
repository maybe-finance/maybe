class AddEmailConfirmationToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :unconfirmed_email, :string
    add_column :users, :email_confirmation_token, :string
    add_column :users, :email_confirmation_sent_at, :datetime

    add_index :users, :email_confirmation_token, unique: true
  end
end
