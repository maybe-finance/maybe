class AddFamilyIdToBalances < ActiveRecord::Migration[7.1]
  def change
    add_reference :balances, :family, foreign_key: true, type: :uuid
    
    #add_index :balances, :family_id, name: 'index_balances_on_family_id'

    Account.all.each do |account|
      account.balances.update_all(family_id: account.family_id)
    end
  end
end
