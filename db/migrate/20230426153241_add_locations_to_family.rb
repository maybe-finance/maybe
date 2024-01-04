class AddLocationsToFamily < ActiveRecord::Migration[7.1]
  def change
    add_column :families, :country, :string
    add_column :families, :region, :string
  end
end
