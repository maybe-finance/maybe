class AddDemographicsToFamily < ActiveRecord::Migration[7.1]
  def change
    add_column :families, :demographics, :jsonb, default: {}
  end
end
