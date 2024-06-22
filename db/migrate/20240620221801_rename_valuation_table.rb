class RenameValuationTable < ActiveRecord::Migration[7.2]
  def change
    rename_table :valuations, :account_valuations
  end
end
