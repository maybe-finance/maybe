class AddPropertyAttributes < ActiveRecord::Migration[7.2]
  def change
    add_column :properties, :year_built, :integer
    add_column :properties, :area_value, :integer
    add_column :properties, :area_unit, :string
  end
end
