class ChangeImportOwner < ActiveRecord::Migration[7.2]
  def up
    add_reference :imports, :family, foreign_key: true, type: :uuid
    add_column :imports, :original_account_id, :uuid

    execute <<-SQL
      UPDATE imports
      SET family_id = (SELECT family_id FROM accounts WHERE accounts.id = imports.account_id),
          original_account_id = account_id
    SQL

    remove_reference :imports, :account, foreign_key: true, type: :uuid
    change_column_null :imports, :family_id, false
  end

  def down
    add_reference :imports, :account, foreign_key: true, type: :uuid

    execute <<-SQL
      UPDATE imports
      SET account_id = original_account_id
    SQL

    remove_reference :imports, :family, foreign_key: true, type: :uuid
    remove_column :imports, :original_account_id, :uuid
    change_column_null :imports, :account_id, false
  end
end
