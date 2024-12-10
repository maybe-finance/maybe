class AddFamilyTimezone < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :timezone, :string
  end
end
