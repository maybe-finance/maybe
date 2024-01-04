class AddUniqueIndexForBalances < ActiveRecord::Migration[7.1]
  def change
    add_index :balances, [:account_id, :security_id, :date, :kind, :family_id], unique: true, name: 'index_balances_on_account_id_security_id_date_kind_family_id'
  end
end