class CreateAccountVehicles < ActiveRecord::Migration[7.2]
  def change
    create_table :account_vehicles, id: :uuid do |t|
      t.timestamps
    end
  end
end
