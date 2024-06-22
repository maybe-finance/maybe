class RenameTransferTable < ActiveRecord::Migration[7.2]
  def change
    rename_table :transfers, :account_transfers
  end
end
