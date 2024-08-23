class AddDetailsToVehicle < ActiveRecord::Migration[7.2]
  def change
    add_column :vehicles, :year, :integer
    add_column :vehicles, :mileage_value, :integer
    add_column :vehicles, :mileage_unit, :string
    add_column :vehicles, :make, :string
    add_column :vehicles, :model, :string
  end
end
