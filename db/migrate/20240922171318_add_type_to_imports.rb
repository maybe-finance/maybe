class AddTypeToImports < ActiveRecord::Migration[7.2]
  def change
    add_column :imports, :type, :string
  end
end
