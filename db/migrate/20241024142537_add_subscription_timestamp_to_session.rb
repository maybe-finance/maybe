class AddSubscriptionTimestampToSession < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :subscribed_at, :datetime
  end
end
