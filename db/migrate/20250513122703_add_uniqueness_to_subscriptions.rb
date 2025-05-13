class AddUniquenessToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    remove_index :subscriptions, :family_id
    add_index :subscriptions, :family_id, unique: true
  end
end
