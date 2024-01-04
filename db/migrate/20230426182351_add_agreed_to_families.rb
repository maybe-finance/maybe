class AddAgreedToFamilies < ActiveRecord::Migration[7.1]
  def change
    add_column :families, :agreed, :boolean, default: false
    add_column :families, :agreed_at, :datetime
    add_column :families, :agreements, :jsonb, default: {}
  end
end
