class AddLimitToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :limit, :bigint, default: 0
  end
end
