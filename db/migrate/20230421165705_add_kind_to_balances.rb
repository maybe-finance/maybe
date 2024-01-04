class AddKindToBalances < ActiveRecord::Migration[7.1]
  def change
    add_column :balances, :kind, :string

    # Set kind based on presence of security_id
    Balance.where(security_id: nil).update_all(kind: "account")
    Balance.where.not(security_id: nil).update_all(kind: "security")
  end
end
