class AddNotesAndExcludedToTransaction < ActiveRecord::Migration[7.2]
  def change
    add_column :transactions, :excluded, :boolean, default: false
    add_column :transactions, :notes, :text
  end
end
