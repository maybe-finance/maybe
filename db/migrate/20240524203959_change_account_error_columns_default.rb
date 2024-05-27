class ChangeAccountErrorColumnsDefault < ActiveRecord::Migration[7.2]
  def up
    change_column_default :accounts, :sync_warnings, from: "[]", to: []
    change_column_default :accounts, :sync_errors, from: "[]", to: []
    Account.update_all(sync_warnings: [])
    Account.update_all(sync_errors: [])
  end
end
