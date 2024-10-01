class AddLocalePreference < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :locale, :string, default: "en"
  end
end
