class AddDetailsToSecurities < ActiveRecord::Migration[7.1]
  def change
    add_column :securities, :logo, :string
    add_column :securities, :logo_source, :string
    add_column :securities, :sector, :string
    add_column :securities, :industry, :string
    add_column :securities, :website, :string
  end
end
