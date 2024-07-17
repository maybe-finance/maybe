class RemoveDefaultFromAccountBalance < ActiveRecord::Migration[7.2]
  def change
    change_column_default :accounts, :balance, from: "0.0", to: nil
    change_column_default :accounts, :currency, from: "USD", to: nil
  end
end
