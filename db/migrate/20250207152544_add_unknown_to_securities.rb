class AddUnknownToSecurities < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :unknown, :boolean, default: false
  end
end
