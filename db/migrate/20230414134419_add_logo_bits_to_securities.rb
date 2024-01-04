class AddLogoBitsToSecurities < ActiveRecord::Migration[7.1]
  def change
    add_column :securities, :logo_svg, :text
    add_column :securities, :logo_colors, :jsonb, default: []
  end
end
