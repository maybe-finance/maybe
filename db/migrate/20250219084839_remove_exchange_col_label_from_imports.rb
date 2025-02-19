class RemoveExchangeColLabelFromImports < ActiveRecord::Migration[7.2]
  def change
    remove_column :imports, :exchange_col_label, :string
  end
end
