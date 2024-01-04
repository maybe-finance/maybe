class RenameAccountType < ActiveRecord::Migration[7.1]
  def change
    rename_column :accounts, :type, :kind
    rename_column :accounts, :subtype, :subkind
  end
end
