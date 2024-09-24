class AddNotesToImport < ActiveRecord::Migration[7.2]
  def change
    add_column :imports, :notes_col_label, :string
  end
end
