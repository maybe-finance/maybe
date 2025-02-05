class RemoveEmailConfirmationSentAtFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :email_confirmation_sent_at, :datetime
  end
end
