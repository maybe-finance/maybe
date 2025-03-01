class AddDefaultPeriodToFamilies < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :default_period, :string
  end
end
