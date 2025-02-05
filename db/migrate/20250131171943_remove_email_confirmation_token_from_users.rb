class RemoveEmailConfirmationTokenFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_index :users, :email_confirmation_token
    remove_column :users, :email_confirmation_token, :string
  end
end
