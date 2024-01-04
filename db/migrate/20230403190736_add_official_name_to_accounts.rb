class AddOfficialNameToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :official_name, :string
  end
end
