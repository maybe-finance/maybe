class AddOptionalAccountForImport < ActiveRecord::Migration[7.2]
  def change
    rename_column :imports, :original_account_id, :account_id
  end
end
