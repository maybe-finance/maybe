class AddLogoUrlToSecurity < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :logo_url, :string
  end
end
