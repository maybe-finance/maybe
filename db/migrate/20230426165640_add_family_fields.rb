class AddFamilyFields < ActiveRecord::Migration[7.1]
  def change
    #:household, :risk, :goals, :recap, :notifications, :agreements

    add_column :families, :household, :string
    add_column :families, :risk, :string
    add_column :families, :goals, :text
    
  end
end
