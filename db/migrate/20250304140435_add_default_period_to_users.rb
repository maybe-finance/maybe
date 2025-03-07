class AddDefaultPeriodToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :default_period, :string, default: "last_30_days", null: false
  end
end
