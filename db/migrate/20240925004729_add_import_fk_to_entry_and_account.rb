class AddImportFkToEntryAndAccount < ActiveRecord::Migration[7.2]
  def change
    add_reference :account_entries, :import, foreign_key: true, type: :uuid
    add_reference :accounts, :import, foreign_key: true, type: :uuid
  end
end
