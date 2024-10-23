class AddOnboardingFields < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :onboarded_at, :datetime
    add_column :families, :date_format, :string, default: "%m-%d-%Y"
    add_column :families, :country, :string, default: "US"
  end
end
